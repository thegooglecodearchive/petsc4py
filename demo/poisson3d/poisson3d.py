import sys, petsc4py
petsc4py.init(sys.argv)

from petsc4py import PETSc
from del2mat import Del2Mat

# number of nodes in each direction
# excluding those at the boundary
n = 32
h = 1.0/(n+1) # grid spacing

# setup linear system matrix
A = PETSc.Mat().create()
A.setSizes([n**3, n**3])
A.setType('python')
shell = Del2Mat(n) # shell context
A.setPythonContext(shell)

# setup linear system vectors
x, b = A.getVecs()
x.set(0.0)
b.set(1.0)

# setup Krylov solver
ksp = PETSc.KSP().create()
pc = ksp.getPC()
ksp.setType('cg')
pc.setType('none')

# iteratively solve linear
# system of equations A*x=b
ksp.setOperators(A)
ksp.setFromOptions()
ksp.solve(b, x)

# scale solution vector to
# account for grid spacing
x.scale(h**2)

try:
    from matplotlib import pylab
except ImportError:
    raise SystemExit("matplotlib not available")
from numpy import mgrid
X, Y =  mgrid[0:1:1j*n,0:1:1j*n]
Z = x[...].reshape(n,n,n)[:,:,n/2-2]
pylab.contourf(X, Y, Z)
pylab.axis('equal')
pylab.colorbar()
pylab.show()
