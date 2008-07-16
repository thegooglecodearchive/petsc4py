# --------------------------------------------------------------------

__all__ = ['PetscConfig',
           'setup', 'Extension',
           'log', 'config',
           'build', 'build_py', 'build_ext',
           'build_src', 'sdist',
           ]

# --------------------------------------------------------------------

import sys, os
from cStringIO import StringIO

from numpy.distutils.core import setup
from numpy.distutils.core import Extension as _Extension
from numpy.distutils.command.config    import config     as _config
from numpy.distutils.command.build     import build      as _build
from numpy.distutils.command.build_src import build_src  as _build_src
from numpy.distutils.command.build_py  import build_py   as _build_py
from numpy.distutils.command.build_ext import build_ext  as _build_ext
from numpy.distutils.command.sdist     import sdist      as _sdist
from numpy.distutils import log
from distutils.errors import DistutilsError

import confutils as cfgutils

# --------------------------------------------------------------------

if not hasattr(sys, 'version_info') or \
       sys.version_info < (2, 4, 0,'final'):
    raise SystemExit("Python 2.4 or later is required "
                     "to build this package.")

# --------------------------------------------------------------------

class PetscConfig:

    def __init__(self, petsc_dir, petsc_arch):
        self.configdict = { }
        if not petsc_dir:
            raise DistutilsError("PETSc not found")
        elif not os.path.isdir(petsc_dir):
            raise DistutilsError("invalid PETSC_DIR: %s" % petsc_dir)
        self.configdict = self._get_petsc_conf(petsc_dir,petsc_arch)
        self.PETSC_DIR  = self['PETSC_DIR']
        self.PETSC_ARCH = self['PETSC_ARCH']
        self.language = self._map_lang(self['PETSC_LANGUAGE'])

    def __call__(self, extension):
        self.configure(extension)

    def __getitem__(self, item):
        return self.configdict[item]

    def configure(self, extension, compiler=None):
        self._configure_extension(extension)
        if compiler is not None:
            self._configure_compiler(compiler)

    def _get_petsc_conf(self, petsc_dir, petsc_arch):
        bmake_dir = os.path.join(petsc_dir, 'bmake')
        if os.path.isdir(bmake_dir):
            return self._get_petsc_conf_old(petsc_dir, petsc_arch)
        else:
            return self._get_petsc_conf_new(petsc_dir, petsc_arch)

    def _get_petsc_conf_old(self, petsc_dir, petsc_arch):
        variables = os.path.join(petsc_dir, 'bmake','common',    'variables')
        petscconf = os.path.join(petsc_dir, 'bmake', petsc_arch, 'petscconf')
        variables = open(variables)
        petscconf = open(petscconf)
        confstr  = 'PETSC_DIR = %s\n'  % petsc_dir
        confstr += 'PETSC_ARCH = %s\n' % petsc_arch
        confstr += variables.read()
        confstr += petscconf.read()
        confstr += 'PACKAGES_INCLUDES = ${MPI_INCLUDE} ${X11_INCLUDE} ${BLASLAPACK_INCLUDE}\n'
        confstr += 'PACKAGES_LIBS = ${MPI_LIB} ${X11_LIB} ${BLASLAPACK_LIB}\n'
        variables.close()
        petscconf.close()
        confdct = cfgutils.makefile(StringIO(confstr))
        return confdct

    def _get_petsc_conf_new(self, petsc_dir, petsc_arch):
        PETSC_DIR  = petsc_dir
        if not petsc_arch or petsc_arch == os.path.sep or \
               not os.path.isdir(os.path.join(petsc_dir, petsc_arch)):
            petsc_arch = ''
            PETSC_ARCH = petsc_arch
            PETSC_INCLUDE =  '-I${PETSC_DIR} -I${PETSC_DIR}/include'
            PETSC_LIB_DIR = '${PETSC_DIR}/lib'
        else:
            PETSC_ARCH = petsc_arch
            PETSC_INCLUDE = '-I${PETSC_DIR} -I${PETSC_DIR}/${PETSC_ARCH}/include -I${PETSC_DIR}/include'
            PETSC_LIB_DIR = '${PETSC_DIR}/${PETSC_ARCH}/lib'
        PETSC_INCLUDE += ' ${PACKAGES_INCLUDES} ${TAU_DEFS} ${TAU_INCLUDE} ${PETSC_BLASLAPACK_FLAGS}'
        variables = os.path.join(petsc_dir, 'conf', 'variables')
        petscconf = os.path.join(petsc_dir, petsc_arch, 'conf', 'petscvariables')
        variables = open(variables)
        petscconf = open(petscconf)
        confstr  = 'PETSC_DIR  = %s\n' % PETSC_DIR
        confstr += 'PETSC_ARCH = %s\n' % PETSC_ARCH
        confstr += variables.read()
        confstr += petscconf.read()
        confstr += 'PETSC_INCLUDE = %s\n' % PETSC_INCLUDE
        confstr += 'PETSC_LIB_DIR = %s\n' % PETSC_LIB_DIR
        confstr += 'PACKAGES_INCLUDES = ${MPI_INCLUDE} ${X11_INCLUDE} ${BLASLAPACK_INCLUDE}\n'
        confstr += 'PACKAGES_LIBS = ${MPI_LIB} ${X11_LIB} ${BLASLAPACK_LIB}\n'
        variables.close()
        petscconf.close()
        confdict = cfgutils.makefile(StringIO(confstr))
        return confdict

    def _map_lang(self, lang):
        langmap = {'CONLY':'c', 'CXXONLY':'c++'}
        return langmap[lang]

    def _configure_extension(self, extension):
        # define macros
        macros = [('PETSC_DIR',  self['PETSC_DIR'])]
        extension.define_macros.extend(macros)
        # includes and libraries
        petsc_inc = cfgutils.flaglist(self['PETSC_INCLUDE'])
        # --- some hackery for petsc 2.3.2 ---
        has_petsc_232 = False
        bmake_dir = os.path.join(self['PETSC_DIR'], 'bmake')
        incprv_dir = os.path.join(self['PETSC_DIR'], 'include', 'private')
        if os.path.isdir(bmake_dir) and os.path.isdir(incprv_dir):
            matimpl_h = os.path.join(incprv_dir, 'matimpl.h')
            if not os.path.exists(matimpl_h): has_petsc_232 = True
        if has_petsc_232:
            include_dirs = petsc_inc.get('include_dirs',[])
            include_dirs.append('src/include/compat/petsc232/impl')
        # -------------------------------------
        lib_info = (self['PETSC_LIB_DIR'], self['PETSC_LIB_BASIC'])
        petsc_lib = cfgutils.flaglist('-L%s %s' % lib_info)
        petsc_lib['runtime_library_dirs'].append(self['PETSC_LIB_DIR'])
        self._configure_ext(extension, petsc_inc, preppend=True)
        self._configure_ext(extension, petsc_lib)
        # extra compiler and linker configuration
        ccflags = self['PCC_FLAGS'].split()
        try:
            ccflags.remove('-Wwrite-strings')
        except ValueError:
            pass
        extension.extra_compile_args.extend(ccflags)
        ldflags = self['PETSC_EXTERNAL_LIB_BASIC'].split()
        extension.extra_link_args.extend(ldflags)

    def _configure_ext(self, ext, dct, preppend=False):
        extdict = ext.__dict__
        for key, values in dct.items():
            if key in extdict:
                for value in values:
                    if value not in extdict[key]:
                        if preppend:
                            extdict[key].insert(0, value)
                        else:
                            extdict[key].append(value)

    def _configure_compiler(self, compiler):
        pass

    def log_info(self):
        log.info('PETSC_DIR:   %s' % self['PETSC_DIR'])
        log.info('PETSC_ARCH:  %s' % (self['PETSC_ARCH'] or '<default>'))
        language    = self['PETSC_LANGUAGE']
        scalar_type = self['PETSC_SCALAR']
        precision   = self['PETSC_PRECISION']
        log.info('language:    %s' % language)
        log.info('scalar-type: %s' % scalar_type)
        log.info('precision:   %s' % precision)


# --------------------------------------------------------------------

class Extension(_Extension):
    pass


# --------------------------------------------------------------------

class config(_config):

    Config = PetscConfig

    user_options = _config.user_options + [
        ('petsc-dir=', None,
         "define PETSC_DIR, overriding environmental variables"),
        ('petsc-arch=', None,
         "define PETSC_ARCH, overriding environmental variables"),
        ]

    def initialize_options(self):
        _config.initialize_options(self)
        self.have_bmake = False
        self.petsc_dir  = None
        self.petsc_arch = None

    def finalize_options(self):
        _config.finalize_options(self)
        self.petsc_dir   = self._get_petsc_dir(self.petsc_dir)
        if self.petsc_dir is  None: return
        isdir, join = os.path.isdir, os.path.join
        self.have_bmake = isdir(join(self.petsc_dir, 'bmake'))
        self.petsc_arch  = self._get_petsc_arch(self.petsc_dir,
                                                self.petsc_arch)
        self.petsc_arch  = self.petsc_arch or []

    def run(self):
        _config.run(self)
        if self.petsc_dir is None: return
        self._log_info()


    def _get_petsc_dir(self, petsc_dir):
        petsc_dir = os.path.expandvars(petsc_dir)
        if not petsc_dir or '$PETSC_DIR' in petsc_dir:
            log.warn("PETSC_DIR not specified")
            return None
        petsc_dir = os.path.expanduser(petsc_dir)
        petsc_dir = os.path.abspath(petsc_dir)
        return self._chk_petsc_dir(petsc_dir)

    def _chk_petsc_dir(self, petsc_dir):
        if not os.path.isdir(petsc_dir):
            log.error('invalid PETSC_DIR: %s (ignored)' % petsc_dir)
            return None
        return petsc_dir

    def _get_petsc_arch(self, petsc_dir, petsc_arch):
        if not petsc_dir:
            return None
        petsc_arch = os.path.expandvars(petsc_arch)
        if self.have_bmake and (not petsc_arch or '$PETSC_ARCH' in petsc_arch):
            log.warn("PETSC_ARCH not specified, trying default")
            petscconf = os.path.join(petsc_dir, 'bmake', 'petscconf')
            if not os.path.exists(petscconf):
                log.warn("file '%s' not found" % petscconf)
                return None
            petscconf = StringIO(file(petscconf).read())
            petscconf = cfgutils.makefile(petscconf)
            petsc_arch = petscconf.get('PETSC_ARCH')
            if not petsc_arch:
                log.warn("default PETSC_ARCH not found")
                return None
        if os.pathsep in petsc_arch:
            arch_sep = os.pathsep
        else:
            arch_sep = ','
        petsc_arch = petsc_arch.split(arch_sep)
        petsc_arch = cfgutils.unique(petsc_arch)
        petsc_arch = [arch for arch in petsc_arch if arch]
        return self._chk_petsc_arch(petsc_dir, petsc_arch)

    def _chk_petsc_arch(self, petsc_dir, petsc_arch):
        valid_archs = []
        for arch in petsc_arch:
            if self.have_bmake:
                arch_path = os.path.join(petsc_dir, 'bmake', arch)
            else:
                arch_path = os.path.join(petsc_dir, arch)
            if not os.path.isdir(arch_path):
                log.warn("invalid PETSC_ARCH '%s' (ignored)" % arch)
                continue
            valid_archs.append(arch)
        if self.have_bmake and not valid_archs:
            log.warn("could not find a valid PETSC_ARCH")
            return None
        return valid_archs

    def _log_info(self):
        log.info('-' * 70)
        log.info('PETSC_DIR:   %s' % self.petsc_dir)
        arch_list = self.petsc_arch
        if not arch_list and not self.have_bmake:
            arch_list = [ None ]
        for arch in arch_list:
            config = self.Config(self.petsc_dir, arch)
            archname = config.PETSC_ARCH or '<default>'
            language = config['PETSC_LANGUAGE']
            compiler = config['PCC']
            scalar_type = config['PETSC_SCALAR']
            precision = config['PETSC_PRECISION']
            log.info('-'*70)
            log.info('PETSC_ARCH:  %s' % archname)
            log.info('language:    %s' % language)
            log.info('compiler:    %s' % compiler)
            log.info('scalar-type: %s' % scalar_type)
            log.info('precision:   %s' % precision)
        log.info('-' * 70)


class build(_build):

    def initialize_options(self):
        _build.initialize_options(self)
        self.petsc_dir  = None
        self.petsc_arch = None

    def finalize_options(self):
        _build.finalize_options(self)
        self.set_undefined_options('config',
                                   ('petsc_dir',  'petsc_dir'),
                                   ('petsc_arch', 'petsc_arch'))


class build_py(_build_py):

    config_file = 'petsc.cfg'

    def build_package_data (self):
        _build_py.build_package_data(self)
        for package, src_dir, build_dir, filenames in self.data_files:
            for filename in filenames:
                if filename == self.config_file:
                    target = os.path.join(build_dir, filename)
                    if os.path.exists(target):
                        self._config(target)
                        break

    def _config(self, py_file):
        PETSC_DIR  = '$PETSC_DIR'
        PETSC_ARCH = '$PETSC_ARCH'
        config_py = open(py_file, 'r')
        config_data = config_py.read()
        config_py.close()
        if '%(PETSC_DIR)s' not in config_data:
            return # already configured
        config = self.get_finalized_command('config')
        petsc_dir  = config.petsc_dir
        petsc_arch = config.petsc_arch
        if petsc_dir:
            PETSC_DIR  = petsc_dir
        if petsc_arch:
            separator   = os.path.pathsep
            PETSC_ARCH = separator.join(petsc_arch)
        log.info('writing %s' % py_file)
        config_py = open(py_file, 'w')
        config_py.write(config_data % vars())
        config_py.close()


class build_src(_build_src):

    def initialize_options(self):
        _build_src.initialize_options(self)

    def finalize_options(self):
        _build_src.finalize_options(self)


class build_ext(_build_ext):

    Config = PetscConfig

    def initialize_options(self):
        _build_ext.initialize_options(self)
        self.petsc_dir  = None
        self.petsc_arch = None
        self._outputs = []

    def finalize_options(self):
        _build_ext.finalize_options(self)
        import sys, os
        from distutils import sysconfig
        if (sys.platform.startswith('linux') or \
            sys.platform.startswith('gnu')) and \
            sysconfig.get_config_var('Py_ENABLE_SHARED'):
            try:
                py_version = sysconfig.get_python_version()
                bad_pylib_dir = os.path.join(sys.prefix, "lib",
                                             "python" + py_version,
                                             "config")
                self.library_dirs.remove(bad_pylib_dir)
            except ValueError:
                pass
            pylib_dir = sysconfig.get_config_var("LIBDIR")
            if pylib_dir not in self.library_dirs:
                self.library_dirs.append(pylib_dir)
        self.set_undefined_options('build',
                                   ('petsc_dir',  'petsc_dir'),
                                   ('petsc_arch', 'petsc_arch'))

    def _get_config(self, petsc_dir, petsc_arch):
        return PetscConfig(petsc_dir, petsc_arch)

    def _copy_ext(self, ext):
        extclass = ext.__class__
        fullname = self.get_ext_fullname(ext.name)
        modpath = str.split(fullname, '.')
        pkgpath = os.path.join('', *modpath[0:-1])
        name = modpath[-1]
        srcs = list(ext.sources)
        macs = list(ext.define_macros)
        incs = list(ext.include_dirs)
        deps = list(ext.depends)
        lang = ext.language
        newext = extclass(name, sources=srcs, depends=deps,
                          define_macros=macs, include_dirs=incs,
                          language=lang)
        return pkgpath, newext

    def _build_ext_arch(self, ext, pkgpath, arch):
        build_temp = self.build_temp
        build_lib  = self.build_lib
        self.build_temp = os.path.join(build_temp, arch)
        self.build_lib  = os.path.join(build_lib, pkgpath, arch)
        _build_ext.build_extension(self, ext)
        self.build_lib  = build_lib
        self.build_temp = build_temp

    def build_extension(self, ext):
        if not isinstance(ext, Extension):
            return _build_ext.build_extension(self, ext)
        petsc_arch = [arch for arch in self.petsc_arch if arch]
        if not petsc_arch:
            petsc_arch = [ None ]
        for arch in petsc_arch:
            config = self._get_config(self.petsc_dir, arch)
            if ext.language != config.language: continue
            config.log_info()
            pkgpath, newext = self._copy_ext(ext)
            config.configure(newext)
            name =  self.distribution.get_name()
            version = self.distribution.get_version()
            distdir = '\'\"%s-%s/\"\'' % (name, version)
            newext.define_macros.append(('__SDIR__', distdir))
            self._build_ext_arch(newext, pkgpath, arch or 'default')

    def get_outputs(self):
        self.check_extensions_list(self.extensions)
        outputs = []
        for ext in self.extensions:
            fullname = self.get_ext_fullname(ext.name)
            filename = self.get_ext_filename(fullname)
            if isinstance(ext, Extension):
                head, tail = os.path.split(filename)
                for arch in self.petsc_arch:
                    outfile = os.path.join(self.build_lib,
                                           head, arch, tail)
                    outputs.append(outfile)
            else:
                outfile = os.path.join(self.build_lib, filename)
                outputs.append(outfile)
        outputs = list(set(outputs))
        return outputs


class sdist(_sdist):

    def run(self):
        self.run_command('build_src')
        _sdist.run(self)


# --------------------------------------------------------------------