from petsc4py import PETSc

class MyNewton(object):
    """
    """
    def __init__(self):
        self.trace = False
        self.call_log = {}

    def _log(self, method, *args):
        self.call_log.setdefault(method, 0)
        self.call_log[method] += 1
        if not self.trace: return
        clsname = self.__class__.__name__
        pargs = []
        for a in args:
            pargs.append(a)
            if isinstance(a, PETSc.Object):
                pargs[-1] = type(a).__name__
        pargs = tuple(pargs)
        print '%-20s' % ('%s.%s%s'% (clsname, method, pargs))

    def create(self,*args):
        self._log('create', *args)

    def destroy(self,*args):
        self._log('destroy', *args)
        if not self.trace: return
        for k, v in self.call_log.items():
            print '%-20s %2d' % (k, v)

    def setFromOptions(self, snes):
        OptDB = PETSc.Options(snes)
        self.trace = OptDB.getTruth('trace',self.trace)
        self._log('setFromOptions',snes)

    def setUp(self, snes):
        self._log('setUp', snes)

    def view(self, snes, viewer):
        self._log('view', snes, viewer)

    def preSolve(self, snes):
        self._log('preSolve', snes)

    def postSolve(self, snes):
        self._log('postSolve', snes)

    def preStep(self, snes, its):
        self._log('preStep', snes, its)

    def postStep(self, snes, its):
        self._log('postStep', snes, its)

    def computeFunction(self, snes, x, F):
        self._log('computeFunction', snes, x, F)
        snes.computeFunction(x, F)

    def computeJacobian(self, snes, x, A, B):
        self._log('computeJacobian', snes, x, A, B)
        flag = snes.computeJacobian(x, A, B)
        return flag

    def linearSolve(self, snes, b, x):
        self._log('linearSolve', snes, b, x)
        snes.ksp.solve(b,x)
        ## return False # not succedd
        if snes.ksp.getConvergedReason() < 0:
            return False # not succedd
        return True # succedd

    def lineSearch(self, snes, x, y, F):
        self._log('lineSearch', snes, x, y, F)
        x.axpy(-1,y)
        snes.computeFunction(x, F)
        ## return False # not succedd
        return True # succedd

    def monitor(self, snes, its, fnorm):
        self._log('monitor', snes, its, fnorm)

    def converged(self, snes, its, *args):
        self._log('converged', snes, its, *args)
        return False

    #create         = None
    #destroy        = None
    #setFromOptions = None
    #setUp          = None
    #view           = None

    #preSolve  = None
    #postSolve = None

    #preStep  = None
    #postStep = None

    #computeFunction = None
    #computeJacobian = None

    #linearSolve = None
    #lineSearch = None

    #monitor     = None
    #converged   = None
