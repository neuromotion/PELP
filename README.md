# PELP

###### Description of Method
This method estimates the length of packet losses in recordings where stimulation is on by leveraging the periodic and regular nature of stimulation artifacts.

  1. If the target device is the Medtronic Summit RC+S, data are loaded using the [analysis-rcs-data](https://github.com/openmind-consortium/Analysis-rcs-data) package.
  2. Prior to running PELP, the period of the stimulation artifact is determined using the period estimation component (FindPeriodLFP.m) of [PARRM](https://github.com/neuromotion/PARRM).
  3. PELP begins by dividing the neural timeseries into continuous chunks separated by data losses.
  4. For each neighboring pair of chunks, a harmonic regression model is fit to the first chunk.
  5. A range of possible packet losses are then tested using the harmonic regression model to predict the data in the second chunk.
  6. The loss size that minimizes the squared error between the model prediction and the second chunk is selected as the true loss size.
  7. The chunks are stitched back together using the estimates for the true loss sizes.

###### Parameter Selection

PELP takes three essential parameters: the period of the artifact (determined using FindPeriodLFP.m), the number of sinusoidal harmonics to fit to the artifact (m), 
and an estimate for the uncertainty in the loss estimates (unc). The number of harmonics can be determined by the number of peaks in the power spectrum of a recording 
with artifact. The uncertainty in the loss estimates depends on the specific device but for the Medtronic Summit RC+S, we've found that a value of 3 samples is typically 
effective. Should it appear that losses are not being estimated correctly, the value of unc should be increased.

###### Example Use Case

An example of how to use PELP for a sample Medtronic Summit RC+S recording is included in PELPDemo.m. The demo loads data using the analysis-rcs-data package with the small
loss flag active, divides the table into chunks, corrects loss sizes using PELP, stitches the table back together, and shows a plot to confirm accurate loss estimation:
![PELP](https://user-images.githubusercontent.com/8806970/166154314-2a132ecd-a7b0-4699-b23c-fdde392dc3e5.jpg)
