#!/bin/bash

# 🎯 Codebase Visualizer Setup Script
# Analyzes your project and starts the visualization server

echo "🚀 Setting up Codebase Visualizer..."

# Check if we're in the right directory
if [ ! -f "src/project_visualizer_analyzer.py" ]; then
    echo "❌ Error: Run this from the codebase-visualizer directory"
    echo "Usage: cd codebase-visualizer && ./setup.sh"
    exit 1
fi

# Get the parent directory (your actual project)
PROJECT_DIR=$(dirname $(pwd))
echo "📁 Project directory: $PROJECT_DIR"

# Run the analyzer on the parent project
echo "🔍 Analyzing project files..."
cd "$PROJECT_DIR"
python3 codebase-visualizer/src/project_visualizer_analyzer.py

# Check if data was generated
if [ ! -f "codebase-visualizer/data/project_visualization_data.json" ]; then
    echo "❌ Error: Failed to generate project data"
    exit 1
fi

echo "✅ Project analysis complete!"

# Go back to visualizer directory
cd codebase-visualizer

# Start the HTTP server
echo "🌐 Starting HTTP server on port 8000..."
echo "📊 Open your browser to: http://localhost:8000/ultimate_project_visualization.html"
echo "⌨️  Press Ctrl+C to stop the server"

python3 -m http.server 8000