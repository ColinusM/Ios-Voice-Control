# 🎯 Codebase Visualizer

An interactive D3.js-powered visualization tool for exploring and understanding project codebases through clustered network graphs.

## 🚀 Features

- **📊 Interactive Network Graph** - Visualize all files and their relationships
- **🎯 Smart Clustering** - Groups files by category (iOS Swift, docs, tests, tools, etc.)
- **🔍 Advanced Search** - Search across file names, paths, content, and concepts
- **📱 Click-to-Zoom** - Click any node to zoom and view detailed file information
- **🎨 Category Filtering** - Focus on specific file types
- **📋 File Details** - View file size, dependencies, summaries, and connections

## 📁 Project Structure

```
codebase-visualizer/
├── ultimate_project_visualization.html  # Main visualization interface
├── src/
│   └── project_visualizer_analyzer.py   # Python analyzer script
├── data/
│   └── project_visualization_data.json  # Generated project data
├── examples/
│   ├── test_visualization.html          # Debug version
│   └── enhanced_visualization.html      # Enhanced sample
└── docs/
    └── README.md                        # This file
```

## 🛠️ Usage

### 1. Generate Project Data

```bash
# From your project root
cd /path/to/your/project
python3 codebase-visualizer/src/project_visualizer_analyzer.py
```

This creates `project_visualization_data.json` with:
- **418 files** analyzed
- **1,989 connections** mapped
- **File metadata** (size, language, dependencies, concepts)
- **Relationship mapping** between files

### 2. Start Visualization

```bash
# Start HTTP server (required for browser security)
cd codebase-visualizer
python3 -m http.server 8000
```

### 3. Open in Browser

Navigate to: `http://localhost:8000/ultimate_project_visualization.html`

## 🎯 Visualization Layout

### **Clustered Architecture View**

Files are organized in logical clusters that reflect real codebase structure:

- **📱 iOS Swift Code** (left) - Main application files
- **📚 Documentation** (top right) - READMEs, guides, onboarding
- **📋 PRP Methodology** (bottom right) - Development process files
- **⚙️ Configuration** (bottom left) - Settings, plists, configs
- **🧪 Tests** (bottom center) - Test files and validation
- **🔧 Tools** (right) - Utilities, scripts, build tools

### **Interactive Controls**

- **🔍 Search Box** - Find files by name, path, or content
- **🎯 Fit Screen** - Auto-zoom to show all nodes
- **💥 Spread Nodes** - Manually redistribute node positions
- **🏷️ Toggle Labels** - Show/hide file names
- **Category Buttons** - Focus on specific file types

## 🎨 Visual Elements

### **Node Properties**
- **Size** - Indicates file complexity/size
- **Color** - Represents file category
- **Connections** - Lines show file relationships
- **Hover Effects** - Highlight on mouse over
- **Click Actions** - Show detailed file information

### **Color Coding**
- 🔵 **Blue** - iOS Swift Code
- 🟢 **Green** - Documentation  
- 🟣 **Purple** - PRP Methodology
- 🟠 **Orange** - Configuration
- 🔴 **Red** - Tests & Validation
- 🟡 **Yellow** - Tools & Utilities

## 🔧 Technical Details

### **Built With**
- **D3.js v7** - Force-directed graph visualization
- **HTML5/CSS3** - Modern web interface
- **Python 3** - Project analysis and data generation
- **JSON** - Data storage and transfer

### **Force Simulation**
- **Clustering Force** - Groups files by category
- **Repulsion Force** - Prevents node overlap
- **Link Force** - Maintains file relationships
- **Collision Detection** - Ensures readable spacing

### **Browser Requirements**
- Modern browser with ES6 support
- Local HTTP server (for security compliance)
- JavaScript enabled

## 📊 Data Format

The analyzer generates rich metadata for each file:

```json
{
  "name": "AuthenticationManager.swift",
  "path": "VoiceControlApp/Authentication/AuthenticationManager.swift", 
  "category": "ios_swift",
  "size": 8000,
  "lines": 200,
  "language": "Swift",
  "content_summary": "Classes: AuthenticationManager. Functions: 12.",
  "key_concepts": ["Authentication", "OAuth", "Security"],
  "dependencies": ["Foundation", "Firebase", "GoogleSignIn"],
  "id": "unique_hash"
}
```

## 🎯 Use Cases

### **For Developers**
- **Understand large codebases** quickly
- **Find file relationships** and dependencies
- **Identify architectural patterns**
- **Locate specific functionality**

### **For Project Managers**
- **Visualize project complexity**
- **Understand team organization**
- **Identify documentation gaps**
- **Plan refactoring efforts**

### **For Code Reviews**
- **See impact of changes**
- **Understand file connections**
- **Identify testing coverage**
- **Validate architecture decisions**

## 🚀 Getting Started

1. **Clone/copy** the `codebase-visualizer` folder to your project
2. **Run the analyzer** on your codebase
3. **Start the HTTP server**
4. **Open the visualization** in your browser
5. **Explore your codebase** interactively!

## 🎨 Customization

### **Adding New Categories**
Edit the `clusters` object in the HTML file to add new file categories:

```javascript
const clusters = {
    'your_category': { x: width * 0.6, y: height * 0.4 },
    // ... existing categories
};
```

### **Modifying Colors**
Update the CSS color classes:

```css
.category-your_category { fill: #your_color; }
```

### **Adjusting Layout**
Modify force simulation parameters for different layouts:

```javascript
.force("charge", d3.forceManyBody().strength(-800))  // Repulsion
.force("link", d3.forceLink().distance(120))         // Link length
```

## 📚 Examples

Check the `examples/` folder for:
- **test_visualization.html** - Simple debug version
- **enhanced_visualization.html** - Sample with styling improvements

---

**Built for understanding codebases visually and interactively! 🎯**