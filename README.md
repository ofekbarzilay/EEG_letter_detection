# Run section 1
in EEGLAB: file-> load exsisting dataset-> EEG Data.set
 FIR filter [0.1 40] Hz: tools -> filter the data -> basic FIR filter -> [0.1,40] Hz
Save into a file 'EEG Data.set'

# Run section 2
Import Events: File -> Load exsisting dataset -> EEG Data.set
Recognize evenst: File -> import event info -> from data channel -> channel:5
Extract Epochs: Tools -> extract epocs -> Epoch limits [-0.2 0.6]
Save into a file 'EEG Data.set'

# Run section 3 (deleting bad epochs based on threshold)
Import Events: File -> Load exsisting dataset -> EEG Data.set
baseline: Tools -> Remove epoch baseline -> Baseline Latency range [-200 0] (save as EEG Data.set)

(smoothing with BPF: tools -> filter the data -> basic FIR filter -> [0.5,10] Hz, order of 4)

# Run section 4
Results should be printed
