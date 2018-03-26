# TODO :- Train for a new dataset with more categories. 
# Look for more ways to bring down the net size. Belive me, your FPGA will thank you for that.

""" AlexNet.

Applying modified Alexnet to Oxford's 17 Category Flower Dataset classification task.

"""

from __future__ import division, print_function, absolute_import

import tflearn
from tflearn.layers.core import input_data, dropout, fully_connected
from tflearn.layers.conv import conv_2d, max_pool_2d
from tflearn.layers.normalization import local_response_normalization
from tflearn.layers.estimator import regression

"""get_n_cores() is for BU SCC. Should be commented if running on laptop with no GPU"""
# Get the assiged number of cores for this job. This is stored in
# the NSLOTS variable, If NSLOTS is not defined throw an exception.
def get_n_cores():
  nslots = os.getenv('NSLOTS')
  if nslots is not None:
    return int(nslots)
  raise ValueError('Environment variable NSLOTS is not defined.')

import oxflower17
X, Y = oxflower17.load_data(one_hot=True, resize_pics=(227, 227))

# Building 'AlexNet' not assigning any padding so let it take default and min one
network = input_data(shape=[None, 227, 227, 3])
network = conv_2d(network, 96, 5, strides=2, activation='relu')
network = conv_2d(network, 96, 5, strides=2, activation='relu')
network = max_pool_2d(network, 3, strides=2)
network = local_response_normalization(network)
network = conv_2d(network, 256, 5, activation='relu')
network = max_pool_2d(network, 3, strides=2)
network = local_response_normalization(network)
network = conv_2d(network, 384, 3, activation='relu')
network = conv_2d(network, 384, 3, activation='relu')
network = conv_2d(network, 256, 3, activation='relu')
network = max_pool_2d(network, 3, strides=2)
network = local_response_normalization(network)
network = fully_connected(network, 4096, activation='tanh')
network = dropout(network, 0.5)
network = fully_connected(network, 4096, activation='tanh')
network = dropout(network, 0.5)
network = fully_connected(network, 17, activation='softmax')
network = regression(network, optimizer='momentum',
                     loss='categorical_crossentropy',
                     learning_rate=0.001)

# Training
model = tflearn.DNN(network, checkpoint_path='model_alexnet',
                    max_checkpoints=1, tensorboard_verbose=2)
model.fit(X, Y, n_epoch=1000, validation_set=0.1, shuffle=True,
          show_metric=True, batch_size=64, snapshot_step=200,
          snapshot_epoch=False, run_id='alexnet_oxflowers17')


# unit test -----------------------------------
session_conf = tf.ConfigProto(
      intra_op_parallelism_threads=get_n_cores()-1,
      inter_op_parallelism_threads=1,
      allow_soft_placement=True, 
      log_device_placement=True)

sess = tf.Session(config=session_conf)
tflearn.is_training(True, session=sess)
train_conv_net()
#testing the image
# for f_in in TEST_SET_FILE_LIST:
#     predictions = model.predict(f_in)
#     print(predictions)

