import asyncio
import tempfile
import os
import cv2
import mediapipe as mp
import numpy as np
from typing import Tuple, Optional
from loguru import logger

from ..utils.config import settings
from ..models.schemas import VerificationVerdict

class DeepfakeDetectionService:
    """Service for detecting deepfakes in videos using MediaPipe and face analysis."""
    
    def __init__(self):
        self.face_mesh = None
        self.face_detection = None
        self.is_initialized = False
        
    async def initialize(self):
        """Initialize the deepfake detection models."""
        try:
            logger.info("Initializing deepfake detection service...")
            
            # Initialize MediaPipe components
            await asyncio.to_thread(self._initialize_mediapipe)
            
            self.is_initialized = True
            logger.info("Deepfake detection service initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize deepfake detection service: {e}")
            raise
    
    def _initialize_mediapipe(self):
        """Initialize MediaPipe face mesh and detection."""
        mp_face_mesh = mp.solutions.face_mesh
        mp_face_detection = mp.solutions.face_detection
        
        self.face_mesh = mp_face_mesh.FaceMesh(
            static_image_mode=False,
            max_num_faces=5,
            refine_landmarks=True,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )
        
        self.face_detection = mp_face_detection.FaceDetection(
            model_selection=1,  # Use full-range model
            min_detection_confidence=0.5
        )
    
    async def detect_deepfake(self, video_path: str) -> Tuple[VerificationVerdict, float, str]:
        """
        Detect deepfake in a video file.
        
        Args:
            video_path: Path to the video file
            
        Returns:
            Tuple of (verdict, confidence, explanation)
        """
        if not self.is_initialized:
            raise RuntimeError("Deepfake detection service not initialized")
        
        try:
            logger.info(f"Analyzing video for deepfake: {video_path}")
            
            # Analyze video frames
            analysis_result = await asyncio.to_thread(self._analyze_video, video_path)
            
            verdict, confidence, explanation = self._interpret_analysis(analysis_result)
            
            logger.info(f"Deepfake analysis complete: {verdict} ({confidence:.2f})")
            return verdict, confidence, explanation
            
        except Exception as e:
            logger.error(f"Deepfake detection failed: {e}")
            return VerificationVerdict.INCONCLUSIVE, 0.0, f"Analysis failed: {str(e)}"
    
    def _analyze_video(self, video_path: str) -> dict:
        """Analyze video frames for deepfake indicators."""
        try:
            cap = cv2.VideoCapture(video_path)
            if not cap.isOpened():
                raise ValueError("Could not open video file")
            
            frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            fps = cap.get(cv2.CAP_PROP_FPS)
            duration = frame_count / fps if fps > 0 else 0
            
            # Sample frames for analysis (analyze every 30th frame or max 50 frames)
            sample_interval = max(1, frame_count // 50)
            analyzed_frames = 0
            
            # Metrics for deepfake detection
            face_consistency_scores = []
            landmark_stability_scores = []
            face_quality_scores = []
            temporal_inconsistencies = []
            
            previous_landmarks = None
            frame_idx = 0
            
            while cap.isOpened() and analyzed_frames < 50:
                ret, frame = cap.read()
                if not ret:
                    break
                
                if frame_idx % sample_interval == 0:
                    # Analyze this frame
                    frame_analysis = self._analyze_frame(frame)
                    
                    if frame_analysis['has_face']:
                        face_quality_scores.append(frame_analysis['face_quality'])
                        
                        # Check landmark stability
                        if previous_landmarks is not None:
                            stability = self._calculate_landmark_stability(
                                previous_landmarks, 
                                frame_analysis['landmarks']
                            )
                            landmark_stability_scores.append(stability)
                        
                        previous_landmarks = frame_analysis['landmarks']
                        analyzed_frames += 1
                
                frame_idx += 1
            
            cap.release()
            
            # Calculate overall metrics
            result = {
                'total_frames': frame_count,
                'analyzed_frames': analyzed_frames,
                'duration': duration,
                'face_detected_frames': len(face_quality_scores),
                'average_face_quality': np.mean(face_quality_scores) if face_quality_scores else 0,
                'landmark_stability': np.mean(landmark_stability_scores) if landmark_stability_scores else 1.0,
                'quality_variance': np.var(face_quality_scores) if face_quality_scores else 0,
            }
            
            return result
            
        except Exception as e:
            logger.error(f"Video analysis failed: {e}")
            return {'error': str(e)}
    
    def _analyze_frame(self, frame) -> dict:
        """Analyze a single frame for deepfake indicators."""
        try:
            # Convert BGR to RGB
            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            
            # Detect faces with MediaPipe
            detection_results = self.face_detection.process(rgb_frame)
            mesh_results = self.face_mesh.process(rgb_frame)
            
            analysis = {
                'has_face': False,
                'face_quality': 0.0,
                'landmarks': None,
                'face_count': 0
            }
            
            if detection_results.detections:
                analysis['face_count'] = len(detection_results.detections)
                analysis['has_face'] = True
                
                # Get the first/largest face
                detection = detection_results.detections[0]
                face_quality = detection.score[0] if detection.score else 0.5
                analysis['face_quality'] = face_quality
            
            if mesh_results.multi_face_landmarks:
                # Extract landmarks for stability analysis
                landmarks = mesh_results.multi_face_landmarks[0]
                analysis['landmarks'] = [(lm.x, lm.y, lm.z) for lm in landmarks.landmark]
            
            return analysis
            
        except Exception as e:
            logger.error(f"Frame analysis failed: {e}")
            return {'has_face': False, 'face_quality': 0.0, 'landmarks': None}
    
    def _calculate_landmark_stability(self, prev_landmarks, curr_landmarks) -> float:
        """Calculate stability between consecutive landmark sets."""
        try:
            if not prev_landmarks or not curr_landmarks:
                return 1.0
            
            # Calculate average movement of key facial landmarks
            key_indices = [0, 17, 33, 61, 78, 93, 132, 164, 172, 187]  # Key facial points
            
            movements = []
            for idx in key_indices:
                if idx < len(prev_landmarks) and idx < len(curr_landmarks):
                    prev_point = np.array(prev_landmarks[idx][:2])  # x, y only
                    curr_point = np.array(curr_landmarks[idx][:2])
                    movement = np.linalg.norm(curr_point - prev_point)
                    movements.append(movement)
            
            if not movements:
                return 1.0
            
            # Return inverse of average movement (higher = more stable)
            avg_movement = np.mean(movements)
            stability = 1.0 / (1.0 + avg_movement * 100)  # Scale and invert
            
            return min(1.0, max(0.0, stability))
            
        except Exception as e:
            logger.error(f"Landmark stability calculation failed: {e}")
            return 1.0
    
    def _interpret_analysis(self, analysis: dict) -> Tuple[VerificationVerdict, float, str]:
        """Interpret analysis results and provide verdict."""
        if 'error' in analysis:
            return VerificationVerdict.INCONCLUSIVE, 0.0, f"Analysis error: {analysis['error']}"
        
        if analysis['analyzed_frames'] < 5:
            return VerificationVerdict.INCONCLUSIVE, 0.0, "Insufficient frames analyzed for reliable detection"
        
        # Calculate deepfake probability based on multiple factors
        suspicious_indicators = 0
        total_indicators = 0
        
        # Factor 1: Face quality consistency
        avg_quality = analysis.get('average_face_quality', 0.5)
        quality_variance = analysis.get('quality_variance', 0.0)
        
        if quality_variance > 0.1:  # High variance in face quality
            suspicious_indicators += 1
        total_indicators += 1
        
        # Factor 2: Landmark stability
        landmark_stability = analysis.get('landmark_stability', 1.0)
        if landmark_stability < 0.7:  # Low stability suggests manipulation
            suspicious_indicators += 1
        total_indicators += 1
        
        # Factor 3: Overall face quality
        if avg_quality > 0.95:  # Unnaturally high quality might indicate AI generation
            suspicious_indicators += 1
        elif avg_quality < 0.3:  # Very low quality might indicate compression artifacts
            suspicious_indicators += 1
        total_indicators += 1
        
        # Calculate confidence and verdict
        if total_indicators == 0:
            return VerificationVerdict.INCONCLUSIVE, 0.0, "Unable to analyze video content"
        
        suspicion_ratio = suspicious_indicators / total_indicators
        
        if suspicion_ratio >= 0.6:
            verdict = VerificationVerdict.FAKE
            confidence = min(0.9, 0.5 + suspicion_ratio * 0.4)
            explanation = f"Video shows {suspicious_indicators}/{total_indicators} deepfake indicators. Face quality variance: {quality_variance:.3f}, landmark stability: {landmark_stability:.3f}"
        elif suspicion_ratio <= 0.3:
            verdict = VerificationVerdict.REAL
            confidence = min(0.9, 0.5 + (1 - suspicion_ratio) * 0.4)
            explanation = f"Video appears authentic with {suspicious_indicators}/{total_indicators} concerning indicators. Analysis shows consistent facial features and natural movement patterns."
        else:
            verdict = VerificationVerdict.INCONCLUSIVE
            confidence = 0.5
            explanation = f"Mixed indicators ({suspicious_indicators}/{total_indicators}) make definitive classification difficult. Manual review recommended."
        
        return verdict, confidence, explanation
    
    async def get_status(self) -> dict:
        """Get the current status of the deepfake detection service."""
        return {
            "name": "deepfake_detection",
            "status": "loaded" if self.is_initialized else "not_loaded",
            "has_mediapipe": self.face_mesh is not None,
            "opencv_available": True  # OpenCV is always available if we got this far
        }

# Create global instance
deepfake_detection_service = DeepfakeDetectionService()
