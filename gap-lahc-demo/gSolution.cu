#include "gSolution.cuh"

Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents){
	printf("Begin createGpuSolution!\n");

	size_solution = sizeof(Solution)
						+ sizeof(Ts)*nJobs //vector s
						+ sizeof(TresUsage)*mAgents; // vector resUsage
	Solution *d_sol;
	gpuMalloc((void**)&d_sol, size_solution);
	printf("malloc solution ok!");
	getchar();
	gpuMemset(d_sol,0,size_solution);
	printf("memset Solution ok!")
	getchar();

	h_solution->s = (Ts*)(d_sol+1);
	h_solution->resUsage = (TresUsage*)(h_solution->s + nJobs);

	printf("adjusting solution GPU pointers");
	getchar();

	gpuMemcpy(d_sol, h_solution, size_solution, cudaMemcpyHostToDevice);

	printf("memcpy Solution ok!");
	getchar();

	return d_sol;

}
