#ifndef SOLUTION_H
#define SOLUTION_H

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "Instance.h"

#include "gpulib/types.h"

EXTERN_C_BEGIN
typedef long int TcostFinal;
typedef long int Texcess;
typedef long int Ts;
typedef long int TresUsage;

typedef struct{
	TcostFinal costFinal;
	Texcess excess;
    Ts *s;
    TresUsage *resUsage;
    Texcess *excess_temp;
}Solution;

Solution* allocationPointersSolution(Instance *inst);

void showSolution(Solution *sol, Instance *inst);

Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents);

Solution* InitialRandom(Instance *inst);

void schc_cpu(Solution *sol, Instance *inst, int L_c);

void createDat(Instance *inst, unsigned int *rank,const char *fileName);

EXTERN_C_END

#endif

