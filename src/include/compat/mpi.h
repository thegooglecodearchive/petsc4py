#ifndef _COMPAT_MPI_H
#define _COMPAT_MPI_H

#if defined(OPEN_MPI)

#ifndef OPENMPI_DLOPEN_LIBMPI
#define OPENMPI_DLOPEN_LIBMPI 1
#endif

#if OPENMPI_DLOPEN_LIBMPI
#if HAVE_DLOPEN

#if HAVE_DLFCN_H
  #include <dlfcn.h>
#else
  #if defined(__linux__)
    #define RTLD_LAZY     0x00001
    #define RTLD_NOW      0x00002
    #define RTLD_LOCAL    0x00000
    #define RTLD_GLOBAL   0x00100
    #define RTLD_NOLOAD   0x00004
    #define RTLD_NODELETE 0x01000
    #define RTLD_DEEPBIND 0x00008
  #elif defined(__APPLE__)
    #define RTLD_LAZY     0x1
    #define RTLD_NOW      0x2
    #define RTLD_LOCAL    0x4
    #define RTLD_GLOBAL   0x8
    #define RTLD_NOLOAD   0x10
    #define RTLD_NODELETE 0x80
    #define RTLD_FIRST    0x100
  #elif defined(__CYGWIN__)
    #define RTLD_LAZY     1
    #define RTLD_NOW      2
    #define RTLD_LOCAL    0
    #define RTLD_GLOBAL   4
  #endif
  #if defined(__cplusplus) || defined(c_plusplus)
  extern "C" {
  #endif
  extern void *dlopen(const char *, int);
  extern void *dlsym(void *, const char *);
  extern int   dlclose(void *);
  extern char *dlerror(void);
  #if defined(__cplusplus) || defined(c_plusplus)
  }
  #endif
#endif

#ifndef RTLD_LAZY
#define RTLD_LAZY 1
#endif
#ifndef RTLD_NOW
#define RTLD_NOW RTLD_LAZY
#endif
#ifndef RTLD_LOCAL
#define RTLD_LOCAL 0
#endif
#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL RTLD_LOCAL
#endif

/*
static void * my_dlopen(const char *name, int mode) {
  void *handle;
  static int called = 0;
  if (!called) {
    called = 1;
    #if HAVE_DLFCN_H
    printf("HAVE_DLFCN_H: yes\n");
    #else
    printf("HAVE_DLFCN_H: no\n");
    #endif
    printf("\n");
    printf("RTLD_LAZY:    0x%X\n", RTLD_LAZY   );
    printf("RTLD_NOW:     0x%X\n", RTLD_NOW    );
    printf("RTLD_LOCAL:   0x%X\n", RTLD_LOCAL  );
    printf("RTLD_GLOBAL:  0x%X\n", RTLD_GLOBAL );
    #ifdef RTLD_NOLOAD
    printf("RTLD_NOLOAD:  0x%X\n", RTLD_NOLOAD );
    #endif
    printf("\n");
  }
  handle = dlopen(name, mode);
  printf("dlopen(\"%s\",0x%X) -> %p\n", name, mode, handle);
  printf("dlerror() -> %s\n\n", dlerror());
  return handle;
}
#define dlopen my_dlopen
*/

static void OPENMPI_dlopen_libmpi(void)
{
  void *handle = 0;
  int mode = RTLD_NOW | RTLD_GLOBAL;
  #ifdef RTLD_NOLOAD
  mode |= RTLD_NOLOAD;
  #endif
#if defined(__CYGWIN__)
  if (!handle) handle = dlopen("cygmpi.dll", mode);
  if (!handle) handle = dlopen("mpi.dll",    mode);
#elif defined(__APPLE__)
  /* Mac OS X */
  if (!handle) handle = dlopen("libmpi.3.dylib", mode);
  if (!handle) handle = dlopen("libmpi.2.dylib", mode);
  if (!handle) handle = dlopen("libmpi.1.dylib", mode);
  if (!handle) handle = dlopen("libmpi.0.dylib", mode);
  if (!handle) handle = dlopen("libmpi.dylib",   mode);
#else
  /* GNU/Linux and others */
  if (!handle) handle = dlopen("libmpi.so.3", mode);
  if (!handle) handle = dlopen("libmpi.so.2", mode);
  if (!handle) handle = dlopen("libmpi.so.1", mode);
  if (!handle) handle = dlopen("libmpi.so.0", mode);
  if (!handle) handle = dlopen("libmpi.so",   mode);
#endif
}

static PetscErrorCode PetscInitialize_OpenMPI(int *argc,char ***args,
                                              const char file[],
                                              const char help[])
{
  OPENMPI_dlopen_libmpi();
  return PetscInitialize(argc,args,file,help);
}
#undef  PetscInitialize
#define PetscInitialize PetscInitialize_OpenMPI

#endif /* HAVE_DLOPEN */
#endif /* OPENMPI_DLOPEN_LIBMPI */

#endif /* OPEN_MPI */

#endif /* _COMPAT_MPI_H */
