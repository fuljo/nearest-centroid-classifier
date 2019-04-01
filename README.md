# Nearest centroid classifier

This hardware component has been designed in VHDL as a project for the _Reti
Logiche_ course at [Politecnico di Milano](https://www.polimi.it).
The design has been synthetised and tested with Xilinx Vivado for hypothetic
FPGA implementation.

## Specification

Let there be a two-dimensional space defined in WxH terms, and the positions of
*N* points, called centroids belonging to that space.
The goal is to implement an hardware component, described in VHDL which
determines the nearst centroids to a given point of the above mentioned space
(according to the Manhattan distance).

The given space is a square (256x256) and the coordinates of the points are
saved in a RAM.
The nearest centroids must be written as a mask: the i-th bit of the mask
is set to 1 if the i-th centroid is the closest and it's set to 0 otherwise.
If there are more centroids "closest" to the given point, there will be multiple
bits set to 1 in the output mask. The LSB of the mask indicates the centroid
number 0 and so on. The output mask will be written in the RAM at a given
address.

Also, an input mask indicates which centroids to compute and which not,
following the same pattern as the output mask.
For the purpose of this project, let *N=8*.

## Contents

+ The design sources are located in the `src` folder
+ The `sim` folder contains various simulation sets
  + `mh_test` and `nk_test` are unit tests for the corresponding entities
  + `ncc_test_single` is a test for the component with hard-coded data
  provided by the professors of the course
  + `ncc_test_file` is a test-bench for the component that reads test cases
  from file and can execute more tests in a row; for file format see the
  provided examples

## Documentation

For the full specification, description of the architecture and synthesis
results see the [attached documentation](https://github.com/fuljo/nearest-centroid-classifier/releases/download/v1.0/nearest-centroid-classifier.pdf)
(in italian).
