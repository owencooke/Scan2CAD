# AM3D
A Python/Qt desktop app for comparing 3D scans of AM parts to their nominal models. Also includes support for performing a remanufacturing feature extraction algorithm between a model and an aligned 3D scan. Used to generate and export the additive and subtractive features as .STL files, which can then be used in the path planning for remanufacturing processes.

## Source Literature
(A Feature Extraction Algorithm for Hybrid Manufacturing and Its Application in Robot-Based Additive and Subtractive Processes)[https://ieeexplore.ieee.org/document/10089593]

## Installation
Requires:
- Python 3x
- Qt 6.3.0, which can be downloaded using the (Qt Online Installer)[https://www.qt.io/download-qt-installer-oss?hsCtaTracking=99d9dd4f-5681-48d2-b096-470725510d34%7C074ddad0-fdef-4e53-8aa8-5e8a876d6ab4]

To install, git clone this repository and install the dependencies listed in `requirements.txt`:
```bash
git clone git@github.com:owencooke/AM3D.git
cd AM3D
python -m venv .venv
.venv/Scripts/Activate
pip install -r requirements.txt
```

## Run
Run the GUI application using `python main.py`.

## Demos
