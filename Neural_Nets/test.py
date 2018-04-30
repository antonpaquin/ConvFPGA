import numpy as np
import struct
import sys
import pdb
np.set_printoptions(threshold=np.inf)
import scipy.misc
caffe_root = '/home/mjhuria/caffe/'  # this file is expected to be in {caffe_root}/examples
sys.path.insert(0, caffe_root + 'python')
import caffe
import matplotlib.pyplot as plt
# %matplotlib inline
caffe.set_mode_cpu()
model_def = '/media/mjhuria/New Volume/Vikram/EC551/Final/27-04/Test.prototxt'
# model_def = '/home/mjhuria/caffe/to_train/caffe_alexnet_train_iter_10000.caffemodel'
model_weights =  '/media/mjhuria/New Volume/Vikram/EC551/Final/27-04/solver_iter_1785.caffemodel'
model_weights_new =  '/media/mjhuria/New Volume/Vikram/EC551/Final/27-04/solver_iter_50000.caffemodel'
net = caffe.Net(model_def,      # defines the structure of the model
                model_weights,  # contains the trained weights
                caffe.TEST)     # use test mode (e.g., don't perfor

new_net = caffe.Net(model_def,      # defines the structure of the model
                model_weights_new,  # contains the trained weights
                caffe.TEST)     # use test mode (e.g., don't perfor
# print [(k, v.data.shape) for k, v in net.blobs.items()]
# print [(k, v[0].data.shape, v[0].data.min(), v[0].data.max()) for k, v in net.params.items()]

conv1_f = net.params['conv1'][0].data   # conv kernels
conv1_fb = net.params['conv1'][1].data  # conv bias
conv2_f = net.params['conv2'][0].data   # conv kernels
conv2_fb = net.params['conv2'][1].data  # conv bias
ip1_f = net.params['fc6'][0].data       # inner product weights
ip1_fb = net.params['fc6'][1].data      # inner product bias
ip2_f = net.params['fc8'][0].data       # inner product weights
ip2_fb = net.params['fc8'][1].data      # inner product bias
ip2_fb_new = new_net.params['fc8'][1].data      # inner product bias
print("conv1")
print(conv1_f)
print("conv1_bias")
print(conv1_fb)
print("conv2")
print(new_net.params['conv1'][0].data)
print("conv1_bias")
print(new_net.params['conv1'][1].data)