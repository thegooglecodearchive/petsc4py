import petsc4py, sys
petsc4py.init(sys.argv)

from petsc4py import PETSc

execfile('petsc-mat.py')
execfile('petsc-ksp.py')

try:
    from matplotlib import pylab
except ImportError:
    raise SystemExit("matplotlib not available")
from numpy import mgrid
X, Y =  mgrid[0:1:1j*m,0:1:1j*n]
Z = x[...].reshape(m,n)
pylab.figure()
pylab.contourf(X,Y,Z)
pylab.plot(X.ravel(),Y.ravel(),'.k')
pylab.axis('equal')
pylab.colorbar()
pylab.show()
