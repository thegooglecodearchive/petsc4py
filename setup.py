#!/usr/bin/env python

"""
PETSc for Python
================

Python bindings for PETSc libraries.

.. tip::

  You can also install `petsc4py-dev`_ with::

    $ pip install petsc==dev petsc4py==dev 

  .. _petsc4py-dev: hg+https://code.google.com/p/petsc4py/#egg=petsc4py-dev
"""

## try:
##     import setuptools
## except ImportError:
##     pass

import sys, os

# --------------------------------------------------------------------
# Metadata
# --------------------------------------------------------------------

from conf.metadata import metadata

def name():
    return 'petsc4py'

def version():
    import re
    fh = open(os.path.join('src', '__init__.py'))
    try: data = fh.read()
    finally: fh.close()
    m = re.search(r"__version__\s*=\s*'(.*)'", data)
    return m.groups()[0]

name     = name()
version  = version()

url      = 'http://%(name)s.googlecode.com/' % vars()
download = url + 'files/%(name)s-%(version)s.tar.gz' % vars()

descr    = __doc__.strip().split('\n'); del descr[1:3]
devstat  = ['Development Status :: 5 - Production/Stable']
keywords = ['PETSc', 'MPI']

metadata['name'] = name
metadata['version'] = version
metadata['description'] = descr.pop(0)
metadata['long_description'] = '\n'.join(descr)
metadata['keywords'] += keywords
metadata['classifiers'] += devstat
metadata['url'] = url
metadata['download_url'] = download

metadata['provides'] = ['petsc4py']
metadata['requires'] = ['numpy']

# --------------------------------------------------------------------
# Extension modules
# --------------------------------------------------------------------

def get_ext_modules(Extension):
    from os   import walk, path
    from glob import glob
    depends = []
    for pth, dirs, files in walk('src'):
        depends += glob(path.join(pth, '*.h'))
        depends += glob(path.join(pth, '*.c'))
    try:
        import numpy
        numpy_includes = [numpy.get_include()]
    except ImportError:
        numpy_includes = []
    return [Extension('petsc4py.lib.PETSc',
                      sources=['src/PETSc.c',
                               'src/libpetsc4py.c',
                               ],
                      include_dirs=['src/include',
                                    ] + numpy_includes,
                      depends=depends)]

# --------------------------------------------------------------------
# Setup
# --------------------------------------------------------------------

from conf.petscconf import setup, Extension
from conf.petscconf import config, build, build_src, build_ext
from conf.petscconf import test, sdist

CYTHON = '0.15'

def run_setup():
    if ('setuptools' in sys.modules):
        from os.path import exists, join
        metadata['zip_safe'] = False
        metadata['install_requires'] = ['numpy']
        if not exists(join('src', 'petsc4py.PETSc.c')):
            metadata['install_requires'] += ['Cython>='+CYTHON]
        PETSC_DIR = os.environ.get('PETSC_DIR')
        if not (PETSC_DIR and os.path.isdir(PETSC_DIR)):
            metadata['install_requires'] += ["petsc>=3.4,<3.5"]
    #
    setup(packages     = ['petsc4py',
                          'petsc4py.lib',],
          package_dir  = {'petsc4py'     : 'src',
                          'petsc4py.lib' : 'src/lib'},
          package_data = {'petsc4py'     : ['include/petsc4py/*.h',
                                            'include/petsc4py/*.i',
                                            'include/petsc4py/*.pxd',
                                            'include/petsc4py/*.pxi',
                                            'include/petsc4py/*.pyx',],
                          'petsc4py.lib' : ['petsc.cfg'],},
          ext_modules  = get_ext_modules(Extension),
          cmdclass     = {'config'     : config,
                          'build'      : build,
                          'build_src'  : build_src,
                          'build_ext'  : build_ext,
                          'test'       : test,
                          'sdist'      : sdist,
                          },
          **metadata)

def chk_cython(VERSION):
    import re
    from distutils import log
    from distutils.version import LooseVersion
    from distutils.version import StrictVersion
    warn = lambda msg='': sys.stderr.write(msg+'\n')
    #
    cython_zip = 'cython.zip'
    if os.path.isfile(cython_zip):
        path = os.path.abspath(cython_zip)
        if sys.path[0] != path:
            sys.path.insert(0, path)
            log.info("adding '%s' to sys.path", cython_zip)
    #
    try:
        import Cython
    except ImportError:
        warn("*"*80)
        warn()
        warn(" You need to generate C source files with Cython!!")
        warn(" Download and install Cython <http://www.cython.org>")
        warn()
        warn("*"*80)
        return False
    #
    try:
        CYTHON_VERSION = Cython.__version__
    except AttributeError:
        from Cython.Compiler.Version import version as CYTHON_VERSION
    REQUIRED = VERSION
    m = re.match(r"(\d+\.\d+(?:\.\d+)?).*", CYTHON_VERSION)
    if m:
        Version = StrictVersion
        AVAILABLE = m.groups()[0]
    else:
        Version = LooseVersion
        AVAILABLE = CYTHON_VERSION
    if (REQUIRED is not None and
        Version(AVAILABLE) < Version(REQUIRED)):
        warn("*"*80)
        warn()
        warn(" You need to install Cython %s (you have version %s)"
             % (REQUIRED, CYTHON_VERSION))
        warn(" Download and install Cython <http://www.cython.org>")
        warn()
        warn("*"*80)
        return False
    #
    return True

def run_cython(source, depends=(), includes=(),
               destdir_c=None, destdir_h=None, wdir=None,
               force=False, VERSION=None):
    from glob import glob
    from distutils import log
    from distutils import dep_util
    from distutils.errors import DistutilsError
    target = os.path.splitext(source)[0]+".c"
    cwd = os.getcwd()
    try:
        if wdir: os.chdir(wdir)
        alldeps = [source]
        for dep in depends:
            alldeps += glob(dep)
        if not (force or dep_util.newer_group(alldeps, target)):
            log.debug("skipping '%s' -> '%s' (up-to-date)",
                      source, target)
            return
    finally:
        os.chdir(cwd)
    if not chk_cython(VERSION):
        raise DistutilsError("requires Cython>=%s" % VERSION)
    log.info("cythonizing '%s' -> '%s'", source, target)
    from conf.cythonize import cythonize
    err = cythonize(source,
                    includes=includes,
                    destdir_c=destdir_c,
                    destdir_h=destdir_h,
                    wdir=wdir)
    if err:
        raise DistutilsError(
            "Cython failure: '%s' -> '%s'" % (source, target))

def build_sources(cmd):
    from os.path import exists, isdir, join
    if (exists(join('src', 'petsc4py.PETSc.c')) and
        not (isdir('.hg') or isdir('.git')) and
        not cmd.force): return
    # petsc4py.PETSc
    source = 'petsc4py.PETSc.pyx'
    depends = ("include/*/*.pxd",
               "PETSc/*.pyx",
               "PETSc/*.pxi",)
    includes = ['include']
    destdir_h = os.path.join('include', 'petsc4py')
    run_cython(source, depends, includes,
               destdir_c=None, destdir_h=destdir_h, wdir='src',
               force=cmd.force, VERSION=CYTHON)
    # libpetsc4py
    source = os.path.join('libpetsc4py', 'libpetsc4py.pyx')
    depends = ["include/petsc4py/*.pxd",
               "libpetsc4py/*.pyx",
               "libpetsc4py/*.pxi"]
    includes = ['include']
    run_cython(source, depends, includes,
               destdir_c=None, destdir_h=None, wdir='src',
               force=cmd.force, VERSION=CYTHON)

build_src.run = build_sources

def run_testsuite(cmd):
    from distutils.errors import DistutilsError
    sys.path.insert(0, 'test')
    try:
        from runtests import main
    finally:
        del sys.path[0]
    err = main(cmd.args or [])
    if err:
        raise DistutilsError("test")

test.run = run_testsuite

# --------------------------------------------------------------------

def main():
    run_setup()

if __name__ == '__main__':
    main()

# --------------------------------------------------------------------
