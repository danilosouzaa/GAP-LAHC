#include "Solution.h"

Solution* allocationPointersSolution(Instance *inst){
	size_t size_solution = sizeof(Solution)
									+ sizeof(Ts)*inst->nJobs //vector s
									+ sizeof(TresUsage)*inst->mAgents; //vector resUsage
	Solution* sol;
	sol = (Solution*)malloc(size_solution);
	assert(sol!=NULL);
	memset(sol,0,size_solution);
	sol->s = (Ts*)(sol+1);
	sol->resUsage = (TresUsage*)(sol->s + inst->nJobs);

	return sol;
}

void showSolution(Solution *sol, Instance *inst){
	int i;
	printf("Data of Solution:\n");
	printf("Cost of Solution: %d\n", sol->costFinal);
	printf("Excess of capacity in Solution: %d\n", sol->excess);
	for(i=0;i<inst->nJobs;i++){
		printf("Job %D allocated in Agent %d.\n",i+1, sol->s[i]+1);
	}
	for(i=0;i<inst->mAgents;i++){
		printf("Resources Usage in Agent %d: %d.\n",i+1,sol->resUsage[i]+1);
	}
}
