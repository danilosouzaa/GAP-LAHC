#include "gSolution.cuh"

const int nThreads =1024;

__global__ void SCHC(Instance *inst, Solution *sol, unsigned int seed, curandState_t* states, int L_c){
	int B_c;
	int N_c;
	int delta;
	int aux;
	__shared__ Solution s[nThreads];
	int c_min;
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
	while(i<=10000){

		op = curand(&states[threadIdx.x])%2;
		//printf("custo final temp: %d\n", s[threadIdx.x].costFinal);
		
		//op = 0;
		if(op == 1){
			do{	delta=0;
				aux1 = curand(&states[threadIdx.x])%inst->nJobs;
				aux2 = curand(&states[threadIdx.x])%inst->mAgents;
				delta = inst->cost[aux1*inst->mAgents+aux2] - inst->cost[aux1*inst->mAgents + s[threadIdx.x].s[aux1]];
			}while((s[threadIdx.x].resUsage[aux2] + inst->resourcesAgent[aux1*inst->mAgents+aux2] > inst->capacity[aux2])||
					(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] - inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1]] > inst->capacity[s[threadIdx.x].s[aux1]]));
		}else{	
			do{
			delta=0;
			do{
				aux1 = curand(&states[threadIdx.x])%inst->nJobs;
				aux2 = curand(&states[threadIdx.x])%inst->nJobs;
				aux3 = curand(&states[threadIdx.x])%inst->nJobs;
			}while((aux1==aux2)||(aux2==aux3)||(aux1==aux3));
			delta = inst->cost[aux1*inst->mAgents+s[threadIdx.x].s[aux2]] + inst->cost[aux2*inst->mAgents+s[threadIdx.x].s[aux3]] + inst->cost[aux3*inst->mAgents+s[threadIdx.x].s[aux1]]  - inst->cost[aux1*inst->mAgents+s[threadIdx.x].s[aux1]] - inst->cost[aux2*inst->mAgents+s[threadIdx.x].s[aux2]] - inst->cost[aux3*inst->mAgents+s[threadIdx.x].s[aux3]];
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
	
	if(threadIdx.x < 1){
		c_min = s[threadIdx.x].costFinal;
		for(i=0;i<nThreads;i++){
			if(s[i].costFinal<c_min){
				c_min = s[i].costFinal;	
			}	  
		}	
	}
	
	free(s[threadIdx.x].s);
	free(s[threadIdx.x].resUsage);
	
	if(threadIdx.x <1 ){
		printf("\ntestes: %d\n", c_min);
	}
}


Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents){
	printf("Begin createGpuSolution!\n");

	size_t size_solution = sizeof(Solution)
										+ sizeof(Ts)*nJobs //vector s
										+ sizeof(TresUsage)*mAgents; // vector resUsage
	Solution *d_sol;
	gpuMalloc((void**)&d_sol, size_solution);
	printf("malloc solution ok!\n");
	//getchar();
	gpuMemset(d_sol,0,size_solution);
	printf("memset Solution ok!\n");
	//getchar();

	h_solution->s = (Ts*)(d_sol+1);
	h_solution->resUsage = (TresUsage*)(h_solution->s + nJobs);

	printf("adjusting solution GPU pointers\n");
	//getchar();

	gpuMemcpy(d_sol, h_solution, size_solution, cudaMemcpyHostToDevice);

	printf("memcpy Solution ok!\n");
	//getchar();

	return d_sol;

}
