#ifndef GULOSO_H
#define GULOSO_H

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include "Instance.h"
#include "Solution.h"

EXTERN_C_BEGIN

int* inicializeVector(Instance *inst, int p1, int p2);

Solution* guloso(Instance *inst, int p1, int p2);

EXTERN_C_END
#endif
