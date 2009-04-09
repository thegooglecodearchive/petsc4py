import sys, petsc4py
petsc4py.init(sys.argv)
from petsc4py import PETSc

# this user class is an application
# context for the nonlinear problem
# at hand; it contains some parametes
# and knows how to compute residuals

class Bratu2D:

    def __init__(self, nx, ny, alpha, impl='numpy'):
        self.nx = nx # x grid size
        self.ny = ny # y grid size
        self.alpha = alpha
        if impl == 'numpy':
            from bratu2dnpy import bratu2d
            order = 'c'
        elif impl == 'f90':
            from bratu2df90 import bratu2d
            order = 'f'
        else:
            raise ValueError('invalid implementation')
        self.compute = bratu2d
        self.order = order

    def evalFunction(self, snes, X, F):
        nx, ny = self.nx, self.ny
        alpha = self.alpha
        order = self.order
        x = X[...].reshape(nx, ny, order=order)
        f = F[...].reshape(nx, ny, order=order)
        self.compute(alpha, x, f)

# convenience access to
# PETSc options database
OptDB = PETSc.Options()

nx = OptDB.getInt('nx', 32)
ny = OptDB.getInt('nx', nx)
alpha = OptDB.getReal('alpha', 6.8)
impl  = OptDB.getString('impl', 'numpy')

# create application context
# and PETSc nonlinear solver
appc = Bratu2D(nx, ny, alpha, impl)
snes = PETSc.SNES().create()

# register the function in charge of
# computing the nonlinear residual
f = PETSc.Vec().createSeq(nx*ny)
snes.setFunction(appc.evalFunction, f)

# configure the nonlinear solver
# to use a matrix-free Jacobian
snes.setUseMF(True)
snes.getKSP().setType('cg')
snes.setFromOptions()

# solve the nonlinear problem
b, x = None, f.duplicate()
x.set(0) # zero inital guess
snes.solve(b, x)

try:
    from matplotlib import pylab
except ImportError:
    raise SystemExit("matplotlib not available")
from numpy import mgrid
X, Y =  mgrid[0:1:1j*nx,0:1:1j*ny]
Z = x[...].reshape(nx,ny)
pylab.figure()
pylab.contourf(X,Y,Z)
pylab.colorbar()
pylab.plot(X.ravel(),Y.ravel(),'.k')
pylab.axis('equal')
pylab.show()
