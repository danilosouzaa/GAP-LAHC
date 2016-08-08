#ifndef SOLUTION_H
#define SOLUTION_H

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "Instance.h"

#include "gpulib/types.h"


typedef int TcostFinal;
typedef int Texcess;
typedef int Ts;
typedef int TresUsage;

typedef struct{
	int costFinal;
	int excess;
    int *s;
    int *resUsage;
}Solution;

Solution* allocationPointersSolution(Instance *inst);

void showSolution(Solution *sol, Instance *inst);

#endif
