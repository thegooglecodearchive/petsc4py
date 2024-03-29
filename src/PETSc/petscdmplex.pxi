# --------------------------------------------------------------------

cdef extern from * nogil:

    int DMPlexCreate(MPI_Comm,PetscDM*)
    int DMPlexClone(PetscDM,PetscDM*)
    int DMPlexCreateFromCellList(MPI_Comm,PetscInt,PetscInt,PetscInt,PetscInt,PetscBool,int[],PetscInt,double[],PetscDM*)

    int DMPlexGetDimension(PetscDM,PetscInt*)
    int DMPlexSetDimension(PetscDM,PetscInt)
    int DMPlexGetChart(PetscDM,PetscInt*,PetscInt*)
    int DMPlexSetChart(PetscDM,PetscInt,PetscInt)
    int DMPlexGetConeSize(PetscDM,PetscInt,PetscInt*)
    int DMPlexSetConeSize(PetscDM,PetscInt,PetscInt)
    int DMPlexGetCone(PetscDM,PetscInt,const_PetscInt*[])
    int DMPlexSetCone(PetscDM,PetscInt,const_PetscInt[])
    int DMPlexInsertCone(PetscDM,PetscInt,PetscInt,PetscInt)
    int DMPlexInsertConeOrientation(PetscDM,PetscInt,PetscInt,PetscInt)
    int DMPlexGetConeOrientation(PetscDM,PetscInt,const_PetscInt*[])
    int DMPlexSetConeOrientation(PetscDM,PetscInt,const_PetscInt[])
    int DMPlexGetSupportSize(PetscDM,PetscInt,PetscInt*)
    int DMPlexSetSupportSize(PetscDM,PetscInt,PetscInt)
    int DMPlexGetSupport(PetscDM,PetscInt,const_PetscInt*[])
    int DMPlexSetSupport(PetscDM,PetscInt,const_PetscInt[])
    int DMPlexInsertSupport(PetscDM,PetscInt,PetscInt,PetscInt)
    #int DMPlexGetConeSection(PetscDM,PetscSection*)
    int DMPlexGetCones(PetscDM,PetscInt*[])
    int DMPlexGetConeOrientations(PetscDM,PetscInt*[])
    int DMPlexGetMaxSizes(PetscDM,PetscInt*,PetscInt*)
    int DMPlexSymmetrize(PetscDM)
    int DMPlexStratify(PetscDM)
    int DMPlexOrient(PetscDM)
    #int DMPlexGetCoordinateSection(PetscDM,PetscSection*)
    #int DMPlexSetCoordinateSection(PetscDM,PetscSection)
    #int DMPlexSetPreallocationCenterDimension(PetscDM,PetscInt)
