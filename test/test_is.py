from petsc4py import PETSc
import unittest
import random

# --------------------------------------------------------------------

class TestISBase(object):

    def tearDown(self):
        self.iset = None

    def testGetSize(self):
        lsize = self.iset.getLocalSize()
        gsize = self.iset.getSize()
        self.assertTrue(lsize <= gsize)
        
    def testDuplicate(self):
        iset = self.iset.duplicate()
        self.assertTrue(self.iset.equal(iset))
        del iset

    def testEqual(self):
        self.assertTrue(self.iset.equal(self.iset))
        iset = self.iset.duplicate()
        self.assertTrue(self.iset.equal(iset))
        del iset

    def testSort(self):
        self.iset.sort()
        self.assertTrue(self.iset.isSorted())
        
    def testDifference(self):
        iset = self.iset.difference(self.iset)
        self.assertEqual(iset.getLocalSize(), 0)
        del iset

    def testSum(self):
        if self.iset.getComm().getSize() > 1:
            return
        self.iset.sort()
        iset = self.iset.duplicate()
        iset.sum(self.iset)
        self.assertTrue(self.iset.equal(iset))
        del iset

    def testExpand(self):
        iset = self.iset.expand(self.iset)
        if self.iset.type == iset.type:
            self.assertTrue(self.iset.equal(iset))
        del iset

    def testProperties(self):
        proplist = ['sizes', 'size', 'local_size',
                    'permutation', 'identity', 'sorted']
        for prop in proplist:
            self.assertTrue(hasattr(self.iset, prop))


# --------------------------------------------------------------------

class TestISGeneral(TestISBase, unittest.TestCase):

    def setUp(self):
        self.idx = list(range(10))
        random.shuffle(self.idx)
        self.iset = PETSc.IS().createGeneral(self.idx)

    def testGetIndices(self):
        idx = self.iset.getIndices()
        self.assertEqual(self.idx, list(idx))

class TestISStride(TestISBase, unittest.TestCase):

    def setUp(self):
        self.iset = PETSc.IS().createStride(10)

    def testGetIndices(self):
        self.assertEqual(list(self.iset.getIndices()),
                         list(range(self.iset.getLocalSize())))

    def testToGeneral(self):
        self.iset.toGeneral()
        self.assertEqual(self.iset.getType(), PETSc.IS.Type.GENERAL)
    
class TestISBlock(TestISBase, unittest.TestCase):

    def setUp(self):
        self.idx = list(range(10))
        random.shuffle(self.idx)
        self.iset = PETSc.IS().createBlock(2, self.idx)

# --------------------------------------------------------------------

if __name__ == '__main__':
    unittest.main()