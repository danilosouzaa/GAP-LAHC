#include "gSolution.cuh"

const int nThreads =1024;

__global__ void SCHC(Instance *inst, Solution *sol, unsigned int seed, curandState_t* states, int L_c){
	int B_c;
	int N_c;
	int delta;
	int aux;
	__shared__ Solution s[nThreads];
	short int aux1;
	short int aux2;
	short int aux3;
	short int op;
	int i;
	s[threadIdx.x].s = (short int*)malloc(sizeof(short int)*inst->nJobs);
	s[threadIdx.x].resUsage = (short int*)malloc(sizeof(short int)*inst->mAgents);
	curand_init(seed,threadIdx.x,0,&states[threadIdx.x]);
	s[threadIdx.x].costFinal = sol->costFinal;
	for(i=0;i<inst->nJobs;i++){
		s[threadIdx.x].s[i] = sol->s[i];
	}
	for(i=0;i<inst->mAgents;i++){
		s[threadIdx.x].resUsage[i] = sol->resUsage[i];
	}

	B_c = sol->costFinal;
	N_c=0;
	i=0;
	while(i<=60000){

		op = curand(&states[threadIdx.x])%2;
		//printf("custo final temp: %d\n", s[threadIdx.x].costFinal);
		delta=0;
		//op = 1;
		if(op == 1){
			do{
				aux1 = curand(&states[threadIdx.x])%inst->nJobs;
				aux2 = curand(&states[threadIdx.x])%inst->mAgents;
				delta = inst->cost[aux1*inst->mAgents+aux2] - inst->cost[aux1*inst->mAgents + s[threadIdx.x].s[aux1]];
			}while((s[threadIdx.x].resUsage[aux2] + inst->resourcesAgent[aux1*inst->mAgents+aux2] > inst->capacity[aux2])||
					(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] - inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1]] > inst->capacity[s[threadIdx.x].s[aux1]]));
		}else{	
			do{
			aux1 = curand(&states[threadIdx.x])%inst->nJobs;
			aux2 = curand(&states[threadIdx.x])%inst->nJobs;
			aux3 = curand(&states[threadIdx.x])%inst->nJobs;
			delta = inst->cost[aux1*inst->mAgents+s[threadIdx.x].s[aux2]] + inst->cost[aux2*inst->mAgents +s[threadIdx.x].s[aux3]] + inst->cost[aux3*inst->mAgents +s[threadIdx.x].s[aux1]]  - inst->cost[aux1*inst->mAgents + s[threadIdx.x].s[aux1]] - inst->cost[aux2*inst->mAgents + s[threadIdx.x].s[aux2]] - inst->cost[aux3*inst->mAgents + s[threadIdx.x].s[aux3]] ;
			}while(
(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] - inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1]] + inst->resourcesAgent[aux3*inst->mAgents + s[threadIdx.x].s[aux1]]>inst->capacity[s[threadIdx.x].s[aux1]])
||
(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux2]] - inst->resourcesAgent[aux2*inst->mAgents + s[threadIdx.x].s[aux2]] + inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux2]]>inst->capacity[s[threadIdx.x].s[aux2]])
||
(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux3]] - inst->resourcesAgent[aux3*inst->mAgents + s[threadIdx.x].s[aux3]] + inst->resourcesAgent[aux2*inst->mAgents + s[threadIdx.x].s[aux3]]>inst->capacity[s[threadIdx.x].s[aux3]])
 );
		}

		if ((s[threadIdx.x].costFinal + delta < B_c)||(s[threadIdx.x].costFinal + delta <= s[threadIdx.x].costFinal)){
			s[threadIdx.x].costFinal += delta;
			if(op==1){
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] -= inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1] ];
				s[threadIdx.x].resUsage[aux2] += inst->resourcesAgent[aux1*inst->mAgents + aux2];
				s[threadIdx.x].s[aux1] = aux2;
			}else{
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux2]] += inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux2]];
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux2]] -= inst->resourcesAgent[aux2*inst->mAgents + s[threadIdx.x].s[aux2]];
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux3]] += inst->resourcesAgent[aux2*inst->mAgents + s[threadIdx.x].s[aux3]];
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux3]] -= inst->resourcesAgent[aux3*inst->mAgents + s[threadIdx.x].s[aux3]];
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] += inst->resourcesAgent[aux3*inst->mAgents + s[threadIdx.x].s[aux1]]; 
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] -= inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1]];
				aux = s[threadIdx.x].s[aux1];
				s[threadIdx.x].s[aux1] = s[threadIdx.x].s[aux2];
				s[threadIdx.x].s[aux2] = s[threadIdx.x].s[aux3];
				s[threadIdx.x].s[aux3] = aux;
			}
		}
		N_c++;
		if(N_c >= L_c){
			B_c = s[threadIdx.x].costFinal;
			N_c = 0;
		}
		i++;
	}
	free(s[threadIdx.x].s);
	free(s[threadIdx.x].resUsage);
	printf("%d\n", s[threadIdx.x].costFinal);

}


Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents){
	printf("Begin createGpuSolution!\n");

	size_t size_solution = sizeof(Solution)
										+ sizeof(Ts)*nJobs //vector s
										+ sizeof(TresUsage)*mAgents; // vector resUsage
	Solution *d_sol;
	gpuMalloc((void**)&d_sol, size_solution);
	printf("malloc solution ok!");
	//getchar();
	gpuMemset(d_sol,0,size_solution);
	printf("memset Solution ok!");
	//getchar();

	h_solution->s = (Ts*)(d_sol+1);
	h_solution->resUsage = (TresUsage*)(h_solution->s + nJobs);

	printf("adjusting solution GPU pointers");
	//getchar();

	gpuMemcpy(d_sol, h_solution, size_solution, cudaMemcpyHostToDevice);

	printf("memcpy Solution ok!");
	//getchar();

	return d_sol;

}
