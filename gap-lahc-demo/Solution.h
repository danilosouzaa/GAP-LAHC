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
typedef char Ts;
typedef short int TresUsage;

typedef struct{
	TcostFinal *costFinal;
    Ts *s;
    TresUsage *resUsage;
}Solution;

Solution* allocationPointersSolution(Instance *inst);

void showSolution(Solution *sol, Instance *inst);

Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents);

void schc_cpu(Solution *sol, Instance *inst, int L_c);

void createDat(Instance *inst, unsigned int *rank,const char *fileName);

void create_solution(Solution *sol, Instance *inst,int pos_best, const char *fileName);

void create_frequency(Instance *inst, unsigned int *rank, const char *fileName);
EXTERN_C_END

#endif

