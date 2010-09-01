#!/usr/bin/env python

#$ python setup.py build_ext --inplace

# a bit of monkeypatching ...
try:
    from numpy.distutils.fcompiler     import FCompiler
    from numpy.distutils.unixccompiler import UnixCCompiler
    FCompiler.runtime_library_dir_option = \
        UnixCCompiler.runtime_library_dir_option.im_func
except Exception:
    pass


def configuration(parent_package='',top_path=None):
    INCLUDE_DIRS = []
    LIBRARY_DIRS = []
    LIBRARIES    = []

    # MPI (hackish)
    import os;
    from distutils.sysconfig import get_config_vars
    from distutils.util import split_quoted
    conf = get_config_vars()
    CC = split_quoted(conf['CC']);
    LD = split_quoted(conf['LDSHARED']);
    CC[0] = os.environ.get('MPICC', 'mpicc')
    LD[0] = os.environ.get('MPILD', CC[0])
    os.environ['CC']       = ' '.join(CC)
    os.environ['LDSHARED'] = ' '.join(LD)
    F90 = os.environ.get('MPIF90', 'mpif90')
    F77 = os.environ.get('MPIF77', 'mpif77')
    os.environ['F90'] = F90
    os.environ['F77'] = F77

    # PETSc
    import os
    PETSC_DIR  = os.environ['PETSC_DIR']
    PETSC_ARCH = os.environ.get('PETSC_ARCH', '')
    from os.path import join, isdir
    if PETSC_ARCH and isdir(join(PETSC_DIR, PETSC_ARCH)):
        INCLUDE_DIRS += [join(PETSC_DIR, PETSC_ARCH, 'include'),
                         join(PETSC_DIR, 'include')]
        LIBRARY_DIRS += [join(PETSC_DIR, PETSC_ARCH, 'lib')]
    else:
        if PETSC_ARCH: pass # XXX should warn ...
        INCLUDE_DIRS += [join(PETSC_DIR, 'include')]
        LIBRARY_DIRS += [join(PETSC_DIR, 'lib')]
    LIBRARIES += ['petscts', 'petscsnes', 'petscksp',
                  'petscdm', 'petscmat',  'petscvec',
                  'petsc']

    # PETSc for Python
    import petsc4py
    INCLUDE_DIRS += [petsc4py.get_include()]

    # Configuration
    from numpy.distutils.misc_util import Configuration
    config = Configuration('', parent_package, top_path)
    config.add_extension('_Bratu3D',
                         sources = ['Bratu3D.i',
                                    'Bratu3D.c'],
                         depends = ['Bratu3D.h'],
                         include_dirs=INCLUDE_DIRS + [os.curdir],
                         libraries=LIBRARIES,
                         library_dirs=LIBRARY_DIRS,
                         runtime_library_dirs=LIBRARY_DIRS)
    return config

if __name__ == "__main__":
    from numpy.distutils.core import setup
    setup(**configuration(top_path='').todict())
