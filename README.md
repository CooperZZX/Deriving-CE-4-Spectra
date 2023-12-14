# Deriving-CE-4-Spectra
Derive the reflectance spectra of Yutu-2, CE-4 and the measurement parameters.

# Instrument Description
The CE-4 visible and near-infrared spectrometer (VNIS) consists of a complementary metal-oxide semiconductor (CMOS) imager with 256 by 256 pixels and a short-wavelength near-infrared (SWIR) detector with a single pixel. It works at a sampling rate of 0.005 μm in the spectral range of 0.45-2.395 μm, aiming at the mineralogy of lunar regolith. 

# Main Function:
CE4_Spec_extract.m calculates CE-4 REFF spectra using the solar irradiance method. 
Referrance:
1. Zhang, H., Yang, Y., Yuan, Y., Jin, W., Lucey, P. G., Zhu, M., Kaydash, V. G., Shkuratov, Y. G., Di, K., Wan, W., Xu, B., Xiao, L., Wang, Z., & Xue, B. (2015). In situ optical measurements of Chang’E‐3 landing site in Mare Imbrium: 1. Mineral abundances inferred from spectral reflectance. Geophysical Research Letters, 42(17), 6945–6950. https://doi.org/10.1002/2015GL065273
2. Yang, Y., Lin, H., Liu, Y., Lin, Y., Wei, Y., Hu, S., Yang, W., Xu, R., He, Z., & Zou, Y. (2020). The Effects of Viewing Geometry on the Spectral Analysis of Lunar Regolith as Inferred by in situ Spectrophotometric Measurements of Chang’E‐4. Geophysical Research Letters, 47(8). https://doi.org/10.1029/2020GL087080

# Sub Function:
extr_SD2BL_par.m extracts the parameters of SWIR channel 

extr_VD2BL_par.m extracts the parameters of Visible channel 

# Additional Data
CE4_VNIS_par.mat contains the instrument parameters of CE-4 VNIS

Sun_Moon_Distance.xlsx contains the distance between the Sun and the Moon. The data is downloaded from https://ssd.jpl.nasa.gov/horizons/app.html#/
