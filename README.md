# Medical Image Enhancer using Verilog HDL

## Overview

**Medical Image Enhancer** is a hardware-oriented digital image processing project implemented using **Verilog HDL**. The project focuses on improving the visual quality of medical images through different image enhancement and noise-removal techniques.

The system implements multiple image processing operations at the RTL level, including filtering, contrast enhancement, histogram equalization, thresholding, and salt-and-pepper noise removal.

The project explores how image enhancement algorithms can be implemented using digital hardware for efficient image processing applications.

## Objectives

- Improve the visual quality and contrast of medical images.
- Reduce noise and unwanted pixel variations.
- Implement image processing algorithms using Verilog HDL.
- Design modular and reusable RTL components.
- Verify functionality through simulation and output analysis.

## Image Processing Techniques

### 1. Contrast Enhancement
Enhances image visibility by improving the intensity distribution of pixels, making important structures more distinguishable.

### 2. Histogram Equalization
Improves image contrast by redistributing pixel intensity values using histogram-based processing.

### 3. Thresholding
Separates image regions based on pixel intensity values to generate enhanced binary representations.

### 4. Salt-and-Pepper Noise Removal
Implements a **3×3 Median Filter** to remove salt-and-pepper noise while preserving important image details.

The median filter replaces the center pixel with the median of the nine neighboring pixel values.

### 5. Advanced Image Enhancement
Includes an advanced RTL implementation that brings image enhancement operations together for simulation and analysis.

## Hardware Architecture

The project is organized into modular Verilog designs:

| Module | Description |
|---|---|
| `image_enhancer.v` | RTL implementation of image enhancement operations |
| `image_enhancer_advanced.v` | Advanced image enhancement implementation |
| `salt_pepper_removal.v` | Salt-and-pepper noise removal using median filtering |
| `tb_image_enhancer.v` | Testbench for image enhancer |
| `tb_image_enhancer_advanced.v` | Testbench for advanced image enhancer |
| `tb_salt_pepper_removal.v` | Testbench for noise removal |

## Repository Structure

```text
Medical_Image_Enhancer_Sim/
│
├── Source_Code/
│   ├── image_enhancer.v
│   ├── image_enhancer_advanced.v
│   ├── salt_pepper_removal.v
│   ├── tb_image_enhancer.v
│   ├── tb_image_enhancer_advanced.v
│   └── tb_salt_pepper_removal.v
│
├── sim/
│   ├── input_image.png
│   ├── input_image.txt
│   ├── reference_clean_dim.png
│   ├── output_contrast.txt
│   ├── output_filtered.txt
│   ├── output_histeq.txt
│   ├── output_thr_histeq.txt
│   ├── output_threshold.txt
│   ├── image_enhancer.vcd
│   ├── image_enhancer_advanced.vcd
│   └── salt_pepper_removal.vcd
│
├── results/
│
├── .gitignore
├── README.md
├── run_isim.bat
├── run_isim.sh
└── run_iverilog.sh
```

## Technologies and Tools

- **Verilog HDL** – RTL design and hardware implementation.
- **Icarus Verilog** – Verilog compilation and simulation.
- **GTKWave** – Waveform visualization.
- **VCD (Value Change Dump)** – Simulation waveform analysis.
- **Digital Image Processing** – Image filtering and enhancement techniques.

## Simulation and Verification

The project uses dedicated Verilog testbenches to verify the functionality of individual image processing modules.

Simulation involves:

1. Loading the input image pixel data.
2. Applying the corresponding image processing operation.
3. Processing pixel values through the RTL modules.
4. Generating enhanced output pixel data.
5. Observing signal transitions and module behavior through waveform analysis.

The simulation outputs are stored in text files, while waveform files (`.vcd`) can be used to inspect the internal signal activity.

## How to Run

### Using Icarus Verilog

1. Clone the repository:

```bash
git clone https://github.com/KusumLata930/Medical_Image_Enhancer.git
```

2. Navigate to the project directory:

```bash
cd Medical_Image_Enhancer
```

3. Run the provided simulation script:

```bash
bash run_iverilog.sh
```

### Using Xilinx ISim

On Windows, execute:

```powershell
.\run_isim.bat
```

On Linux:

```bash
bash run_isim.sh
```

*Note: The simulation scripts require the corresponding simulator to be installed and configured in your system.*

## Applications

- Medical image preprocessing.
- Image denoising and quality enhancement.
- Digital image processing hardware.
- FPGA-based image processing systems.
- Hardware acceleration of image enhancement algorithms.

## Future Scope

- FPGA implementation and hardware testing.
- Optimization of RTL architecture for reduced hardware resource utilization.
- Real-time medical image processing.
- Pipeline-based processing for improved throughput.
- Integration of additional image enhancement algorithms.

## Author

**Kusum Lata**

B.Tech – Electronics and Communication Engineering (IIoT)  
National Institute of Technology, Kurukshetra

- GitHub: [KusumLata930](https://github.com/KusumLata930)
- Project Repository: [Medical_Image_Enhancer](https://github.com/KusumLata930/Medical_Image_Enhancer)

---

