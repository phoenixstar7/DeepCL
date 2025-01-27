cdef class NeuralNet:
    cdef cDeepCL.NeuralNet *thisptr

    def __cinit__(self, DeepCL cl, planes = None, size = None):
#        print('__cinit__(planes,size)')
        if planes == None and size == None:
            self.thisptr = cDeepCL.NeuralNet.instance(cl.thisptr)
        else:
            self.thisptr = cDeepCL.NeuralNet.instance3(cl.thisptr, planes, size)

    def __dealloc__(self):
        self.thisptr.deleteMe()

    def asString(self):
        print('about to call asnewcharstar')
        cdef const char *result_charstar = self.thisptr.asNewCharStar()
        print('got char *result')
        cdef str result = str(result_charstar.decode('UTF-8'))
        CppRuntimeBoundary.deepcl_deleteCharStar(result_charstar)
        return result

#    def myprint(self):
#        self.thisptr.print()

    def setBatchSize(self, int batchSize):
        self.thisptr.setBatchSize(batchSize) 
    def forward(self, const float[:] images):
        self.thisptr.forward(&images[0])
    def forwardList(self, imagesList):
        cdef c_array.array imagesArray = array('f', imagesList)
        cdef float[:] imagesArray_view = imagesArray
        self.thisptr.forward(&imagesArray_view[0])
    def backwardFromLabels(self, int[:] labels):
        return self.thisptr.backwardFromLabels(&labels[0]) 
    def backward(self, float[:] expectedOutput):
        return self.thisptr.backward(&expectedOutput[0])
    def calcNumRight(self, int[:] labels):
        return self.thisptr.calcNumRight(&labels[0])
    def addLayer(self, LayerMaker2 layerMaker):
        self.thisptr.addLayer(layerMaker.baseptr)
    def getLayer(self, int index):
        cdef cDeepCL.Layer *cLayer = self.thisptr.getLayer(index)
        if cLayer == NULL:
            raise Exception('layer ' + str(index) + ' not found')
        layer = Layer()
        layer.set_thisptr(cLayer) # note: once neuralnet out of scope, these 
                                                    # are no longer valid
        if layer.getClassName() == 'SoftMaxLayer':
            layer.set_thisptr(<cDeepCL.Layer *>(0))
            layer = SoftMax()
            layer.set_thisptr(cLayer)
        return layer
    def getLastLayer(self):
        return self.getLayer(self.getNumLayers() - 1)
    def getNumLayers(self):
        return self.thisptr.getNumLayers()
    def getOutput(self):
        cdef const float *output = self.thisptr.getOutput()
        cdef int outputNumElements = self.thisptr.getOutputNumElements()
        cdef c_array.array outputArray = array('f', [0] * outputNumElements)
        for i in range(outputNumElements):
            outputArray[i] = output[i]
        return outputArray
    def setTraining(self, training): # 1 is, we are training net, 0 is we are not
                            # used for example by randomtranslations layer (for now,
                            # used only by randomtranslations layer)
        self.thisptr.setTraining(training)
