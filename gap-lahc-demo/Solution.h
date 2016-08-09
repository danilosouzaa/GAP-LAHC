#ifndef SOLUTION_H
#define SOLUTION_H

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "Instance.h"

#include "gpulib/types.h"

EXTERN_C_BEGIN
typedef int TcostFinal;
typedef int Texcess;
typedef short int Ts;
typedef short int TresUsage;

typedef struct{
	TcostFinal costFinal;
	Texcess excess;
    Ts *s;
    TresUsage *resUsage;
}Solution;

Solution* allocationPointersSolution(Instance *inst);

void showSolution(Solution *sol, Instance *inst);

Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents);

EXTERN_C_END

#endif

