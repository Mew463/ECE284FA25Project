# Alpha 3: Leaky ReLU activation function 
* added to the special function processor (SFP) 
* perform a arithmetic right shift of 6 to negative input instead of outputting zeros. 
  * psum >> 6 is equivalent to multiplying by 0.015625
  * right shift is easy for hardware  

### This improves the flow of gradients during backpropagation and leads to more stable training.

