#include "gSolution.cuh"


__global__ void SCHC(Instance *inst, Solution *sol, unsigned int seed, curandState_t* states, int L_c){
	int B_c[10];
	int N_c[10];
	int delta[10];
	Solution s[10];
	int aux1[10];
	int aux2[10];
	int op[10];
	int i[10];
	curand_init(seed,threadIdx.x,0,&states[threadIdx.x]);

	if(threadIdx.x < 10){
		s[threadIdx.x] = *sol;
		B_c[threadIdx.x] = sol->costFinal;
		N_c[threadIdx.x] = 0;
		i[threadIdx.x]=0;
		while(i[threadIdx.x]<=10000){
			//op[threadIdx.x] = curand(&states[threadIdx.x])%2;
			op[threadIdx.x] = 0;
			if(op[threadIdx.x] == 1){
				do{
					aux1[threadIdx.x] = curand(&states[threadIdx.x])%inst->nJobs;
					aux2[threadIdx.x] = curand(&states[threadIdx.x])%inst->mAgents;
					delta[threadIdx.x] = s[threadIdx.x].costFinal - inst->cost[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]]] + inst->cost[aux1[threadIdx.x]*inst->mAgents+aux2[threadIdx.x]];
				}while(s[threadIdx.x].resUsage[aux2[threadIdx.x]] + inst->resourcesAgent[aux1[threadIdx.x]*inst->mAgents+aux2[threadIdx.x]] > inst->capacity[aux2[threadIdx.x]]);
			}else{
				do{
					aux1[threadIdx.x] = curand(&states[threadIdx.x])%inst->nJobs;
					do{
						aux2[threadIdx.x] = curand(&states[threadIdx.x])%inst->nJobs;
					}while(aux1[threadIdx.x]==aux2[threadIdx.x]);
					delta[threadIdx.x] = s[threadIdx.x].costFinal - inst->cost[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]]] - inst->cost[aux2[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux2[threadIdx.x]]];
					delta[threadIdx.x] += inst->cost[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux2[threadIdx.x]]] + inst->cost[aux2[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]]];
				}while((s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1[threadIdx.x]]] - inst->resourcesAgent[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]]] + inst->resourcesAgent[aux2[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]]]>inst->capacity[s[threadIdx.x].s[aux1[threadIdx.x]]])
						||(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux2[threadIdx.x]]] - inst->resourcesAgent[aux2[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux2[threadIdx.x]]] +  inst->resourcesAgent[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux2[threadIdx.x]]]> inst->capacity[s[threadIdx.x].s[aux2[threadIdx.x]]]));
			}
			printf("Delta: %d i: %d\n", delta[threadIdx.x], i[threadIdx.x]);
			if ((delta[threadIdx.x] < B_c[threadIdx.x])||(delta[threadIdx.x]<=s[threadIdx.x].costFinal)){
				s[threadIdx.x].costFinal = delta[threadIdx.x];
				if(op[threadIdx.x]==1){
					s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1[threadIdx.x]]] -= inst->resourcesAgent[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]] ];
					s[threadIdx.x].resUsage[aux2[threadIdx.x]] += inst->resourcesAgent[aux1[threadIdx.x]*inst->mAgents + aux2[threadIdx.x]];
					s[threadIdx.x].s[aux1[threadIdx.x]] = aux2[threadIdx.x];
				}else{
					s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1[threadIdx.x]]]-= inst->resourcesAgent[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]]];
					s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1[threadIdx.x]]]+= inst->resourcesAgent[aux2[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux1[threadIdx.x]]];
					s[threadIdx.x].resUsage[s[threadIdx.x].s[aux2[threadIdx.x]]]-= inst->resourcesAgent[aux2[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux2[threadIdx.x]]];
					s[threadIdx.x].resUsage[s[threadIdx.x].s[aux2[threadIdx.x]]]+= inst->resourcesAgent[aux1[threadIdx.x]*inst->mAgents + s[threadIdx.x].s[aux2[threadIdx.x]]];
					delta[threadIdx.x] = s[threadIdx.x].s[aux1[threadIdx.x]];
					s[threadIdx.x].s[aux1[threadIdx.x]] = s[threadIdx.x].s[aux2[threadIdx.x]];
					s[threadIdx.x].s[aux2[threadIdx.x]] = delta[threadIdx.x];
				}
			}
			N_c[threadIdx.x]++;
			if(N_c[threadIdx.x] >= L_c){
				B_c[threadIdx.x] = s[threadIdx.x].costFinal;
				N_c[threadIdx.x]=0;
			}


			i[threadIdx.x]++;
		}

		printf("Custo final: %d\n", s[threadIdx.x].costFinal);
	}
}


Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents){
	printf("Begin createGpuSolution!\n");

	size_t size_solution = sizeof(Solution)
								+ sizeof(Ts)*nJobs //vector s
								+ sizeof(TresUsage)*mAgents; // vector resUsage
	Solution *d_sol;
	gpuMalloc((void**)&d_sol, size_solution);
	printf("malloc solution ok!");
	getchar();
	gpuMemset(d_sol,0,size_solution);
	printf("memset Solution ok!");
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
