# Scan2CAD
A Python/Qt desktop app for comparing 3D scans of AM parts to their nominal models. Also includes support for performing a remanufacturing feature extraction algorithm between a model and an aligned 3D scan. Used to generate and export the additive and subtractive features as .STL files, which can then be used in the path planning for remanufacturing processes.

## Source Literature
[A Feature Extraction Algorithm for Hybrid Manufacturing and Its Application in Robot-Based Additive and Subtractive Processes](https://ieeexplore.ieee.org/document/10089593)

## Installation
Requires:
- Python 3x
- Qt 6.3.0, which can be downloaded using the [Qt Online Installer](https://www.qt.io/download-qt-installer-oss?hsCtaTracking=99d9dd4f-5681-48d2-b096-470725510d34%7C074ddad0-fdef-4e53-8aa8-5e8a876d6ab4)

To install, git clone this repository and install the dependencies listed in `requirements.txt`:
```bash
git clone git@github.com:owencooke/AM3D.git
cd AM3D
python -m venv .venv
.venv/Scripts/Activate
pip install -r requirements.txt
```

## Run
Start the GUI application by running `main.py` in your Python virtual environment.

## Demos
**Scan-to-CAD Alignment/Comparison**

https://user-images.githubusercontent.com/90405643/233686785-594272ca-42ff-4666-ad62-37cee8e348e3.mp4

<br/>

**Remanufacturing Feature Extraction**


https://user-images.githubusercontent.com/90405643/233680959-b6dfa5d6-c5da-450e-9dd4-7d42b603ecdc.mp4

>**Note** the blue model is the 3D scan of a printed part, while the grey model is a CAD model of the desired remanufactured product.
