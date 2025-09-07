#!/usr/bin/env python3
"""
Convenience scripts for running the fake news detector API with UV.
Run with: uv run scripts.py <command>
"""
import sys
import subprocess
import os

def dev():
    """Run the development server with hot reload."""
    subprocess.run([
        "uvicorn", "main:app", 
        "--reload", 
        "--host", "127.0.0.1", 
        "--port", "8000",
        "--log-level", "info"
    ])

def prod():
    """Run the production server."""
    subprocess.run([
        "uvicorn", "main:app", 
        "--host", "0.0.0.0", 
        "--port", "8000",
        "--workers", "4",
        "--log-level", "warning"
    ])

def test():
    """Run tests with pytest."""
    subprocess.run(["pytest", "-v", "--cov=app", "--cov-report=term-missing"])

def lint():
    """Run linting tools."""
    print("Running Black...")
    subprocess.run(["black", ".", "--check"])
    
    print("Running isort...")
    subprocess.run(["isort", ".", "--check-only"])
    
    print("Running flake8...")
    subprocess.run(["flake8", "."])

def format():
    """Format code with black and isort."""
    print("Formatting with Black...")
    subprocess.run(["black", "."])
    
    print("Sorting imports with isort...")
    subprocess.run(["isort", "."])

def typecheck():
    """Run type checking with mypy."""
    subprocess.run(["mypy", "app/"])

def install_models():
    """Download and install required AI models."""
    import os
    
    model_dir = "models"
    os.makedirs(model_dir, exist_ok=True)
    
    print("Setting up model cache directory...")
    print(f"Model cache directory created at: {os.path.abspath(model_dir)}")
    print("Note: Speech-to-text now uses Groq API instead of local models")
    
    # Future model installations can be added here
    print("No local models to install. API-based services will be used when API keys are provided.")
    print("See .env.template for required API keys.")
    
    # Check if .env file exists
    if not os.path.exists(".env"):
        print("\nWARNING: .env file not found. Please copy env.template to .env and add your API keys.")
        print("cp env.template .env")

def help():
    """Show available commands."""
    print("Available commands:")
    print("  dev          - Run development server with hot reload")
    print("  prod         - Run production server")
    print("  test         - Run tests")
    print("  lint         - Run linting checks")
    print("  format       - Format code")
    print("  typecheck    - Run type checking")
    print("  install-models - Download required AI models")
    print("  help         - Show this help message")

def main():
    if len(sys.argv) < 2:
        help()
        return
    
    command = sys.argv[1].replace('-', '_')
    
    commands = {
        'dev': dev,
        'prod': prod,
        'test': test,
        'lint': lint,
        'format': format,
        'typecheck': typecheck,
        'install_models': install_models,
        'help': help,
    }
    
    if command in commands:
        commands[command]()
    else:
        print(f"Unknown command: {sys.argv[1]}")
        help()

if __name__ == "__main__":
    main()
