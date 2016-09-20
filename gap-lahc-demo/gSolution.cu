#include "gSolution.cuh"

const int nThreads = 1024;

__global__ void SCHC(Instance *inst, Solution *sol, unsigned int *seed, unsigned int *rank, curandState_t* states, int L_c)
{
	int B_c;
	int N_c;
	int delta;
	int aux;
	int test_ite = 0 ;

	__shared__ Solution s[nThreads];
	__shared__ int max_ite;
	if(threadIdx.x<1){
		max_ite = 0;
	}

	int c_min;
	int c_max;
	//int c_media=0;
	short int aux1;
	short int aux2;
	//short int aux3;
	short int aux_p[10];
	short int op;
	short int t;
	int i,j, ite, flag, excess_temp;
	s[threadIdx.x].s = (short int*)malloc(sizeof(short int)*inst->nJobs);
	s[threadIdx.x].resUsage = (short int*)malloc(sizeof(short int)*inst->mAgents);
	curand_init(seed[threadIdx.x],threadIdx.x,0,&states[threadIdx.x]);
	s[threadIdx.x].costFinal = sol->costFinal;
	s[threadIdx.x].excess = sol->excess;
	if(threadIdx.x==1){
		printf("Custo da solucao inicial: %d\n", s[threadIdx.x].costFinal);
	}
	for(i=0; i<inst->nJobs; i++)
	{
		s[threadIdx.x].s[i] = sol->s[i];
	}
	for(i=0; i<inst->mAgents; i++)
	{
		s[threadIdx.x].resUsage[i] = sol->resUsage[i];
	}
	L_c = curand(&states[threadIdx.x])%101 + 50;
	B_c = sol->costFinal;
	N_c=0;
	ite=0;
	while(ite<=100000)
	{
		//do
		//{
			op = curand(&states[threadIdx.x])%2;
			//printf("custo final temp: %d\n", s[threadIdx.x].costFinal);
			aux=0;
			excess_temp = 0;
			// op = 1;
			if(op == 1)
			{
				delta=0;
				aux1 = curand(&states[threadIdx.x])%inst->nJobs;
				aux2 = curand(&states[threadIdx.x])%inst->mAgents;
				delta = inst->cost[aux1*inst->mAgents+aux2] - inst->cost[aux1*inst->mAgents + s[threadIdx.x].s[aux1]];
				if(s[threadIdx.x].resUsage[aux2] + inst->resourcesAgent[aux1*inst->mAgents+aux2] > inst->capacity[aux2]){
					excess_temp += s[threadIdx.x].resUsage[aux2] + inst->resourcesAgent[aux1*inst->mAgents+aux2] - inst->capacity[aux2];
				}
				if(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] - inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1]] > inst->capacity[s[threadIdx.x].s[aux1]]){
					excess_temp += s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] - inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1]] - inst->capacity[s[threadIdx.x].s[aux1]];
				}
				//{
				//	aux=1;
				//}
			}
			else
			{
				delta=0;
				aux = 1;
				t = curand(&states[threadIdx.x])%8 + 2;
				aux_p[0] = curand(&states[threadIdx.x])%inst->nJobs;
				delta -= inst->cost[ aux_p[0]*inst->mAgents+s[threadIdx.x].s[aux_p[0]]];
				for(i=1; i<=t; i++)
				{

					aux_p[i] = curand(&states[threadIdx.x])%inst->nJobs;
					aux1 = aux_p[i];
					aux_p[t]= inst->nJobs-1;
					do{
						flag = 0;
						for(j=0; j<i; j++)
						{
							if(aux_p[i]==aux_p[j])
							{
								flag = 1;
							}
						}
						if((s[threadIdx.x].s[aux_p[i]] != s[threadIdx.x].s[aux_p[i-1]])&&( s[threadIdx.x].s[aux_p[0]] != s[threadIdx.x].s[aux_p[t]] ) &&(flag!=1)/*&&(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[i]]] - inst->resourcesAgent[aux_p[i]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]] + inst->resourcesAgent[aux_p[i-1]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]] <= inst->capacity[s[threadIdx.x].s[aux_p[i]]])*/){
							if(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[i]]] - inst->resourcesAgent[aux_p[i]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]] + inst->resourcesAgent[aux_p[i-1]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]] > inst->capacity[s[threadIdx.x].s[aux_p[i]]]){
								excess_temp += s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[i]]] - inst->resourcesAgent[aux_p[i]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]] + inst->resourcesAgent[aux_p[i-1]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]] - inst->capacity[s[threadIdx.x].s[aux_p[i]]];
							}


							break;
						}
						aux_p[i]=(aux_p[i]+1)%(inst->nJobs);
					}while(aux_p[i]!=aux1);
					if(aux1==aux_p[i]){
						aux=0;
					}


					/*while((i==t)&&(s[threadIdx.x].s[aux_p[0]]==s[threadIdx.x].s[aux_p[t]]))
						{
							aux_p[i] = curand(&states[threadIdx.x])%inst->nJobs;
						}
						for(j=0; j<i; j++)
						{
							if(aux_p[i]==aux_p[j])
							{
								flag = 1;
							}
						}*/
					delta += inst->cost[aux_p[i-1]*inst->mAgents+s[threadIdx.x].s[aux_p[i]]];
					delta -= inst->cost[aux_p[i]*inst->mAgents+s[threadIdx.x].s[aux_p[i]]];


				}
				delta += inst->cost[aux_p[t]*inst->mAgents + s[threadIdx.x].s[aux_p[0]]];
				if(s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[0]]] - inst->resourcesAgent[aux_p[0]*inst->mAgents + s[threadIdx.x].s[aux_p[0]]] + inst->resourcesAgent[aux_p[t]*inst->mAgents + s[threadIdx.x].s[aux_p[0]]]>inst->capacity[s[threadIdx.x].s[aux_p[0]]])
				{
					excess_temp += s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[0]]] - inst->resourcesAgent[aux_p[0]*inst->mAgents + s[threadIdx.x].s[aux_p[0]]] + inst->resourcesAgent[aux_p[t]*inst->mAgents + s[threadIdx.x].s[aux_p[0]]]-inst->capacity[s[threadIdx.x].s[aux_p[0]]];
				//	aux=0;
				}
			}
			test_ite++;
		//}
		//while(aux==0);
		if(test_ite> max_ite){
			max_ite = test_ite;
		}
		test_ite = 0;
		//excess_temp = 0;
		for(i=0;i<inst->mAgents;i++){
				 if(s[threadIdx.x].resUsage[i]-inst->capacity[i]>0){
					 excess_temp += sol->resUsage[i]-inst->capacity[i];
				 }
		}


		if ((s[threadIdx.x].costFinal + delta + excess_temp*100000  < B_c)||(s[threadIdx.x].costFinal + delta + excess_temp*100000 <= s[threadIdx.x].costFinal + s[threadIdx.x].excess*100000 ))
		{
			s[threadIdx.x].costFinal += delta;
			s[threadIdx.x].excess = excess_temp;
			if(op==1)
			{
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux1]] -= inst->resourcesAgent[aux1*inst->mAgents + s[threadIdx.x].s[aux1] ];
				s[threadIdx.x].resUsage[aux2] += inst->resourcesAgent[aux1*inst->mAgents + aux2];
				s[threadIdx.x].s[aux1] = aux2;
			}
			else
			{
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[0]]] += inst->resourcesAgent[aux_p[t]*inst->mAgents + s[threadIdx.x].s[aux_p[0]]];
				s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[0]]] -= inst->resourcesAgent[aux_p[0]*inst->mAgents + s[threadIdx.x].s[aux_p[0]]];
				aux = s[threadIdx.x].s[aux_p[0]];
				for(i=1; i<=t; i++)
				{
					s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[i]]] += inst->resourcesAgent[aux_p[i-1]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]];
					s[threadIdx.x].resUsage[s[threadIdx.x].s[aux_p[i]]] -= inst->resourcesAgent[aux_p[i]*inst->mAgents + s[threadIdx.x].s[aux_p[i]]];
					s[threadIdx.x].s[aux_p[i-1]] = s[threadIdx.x].s[aux_p[i]];
				}
				s[threadIdx.x].s[aux_p[t]] = aux;
			}
		}
		N_c++;
		if(N_c >= L_c)
		{
			B_c = s[threadIdx.x].costFinal + s[threadIdx.x].excess*100000;
			N_c = 0;
		}
		ite++;
	}

	if(threadIdx.x < 1)
	{
		c_min = s[threadIdx.x].costFinal + s[threadIdx.x].excess*100000;
		c_max = s[threadIdx.x].costFinal;
		for(i=0; i<nThreads; i++)
		{
			for(j=0;j<inst->nJobs;j++){
				atomicInc(&rank[j * inst->mAgents +s[i].s[j]],nThreads+1);
			}

			if(s[i].costFinal + s[i].excess*100000 < c_min)
			{
 				c_min = s[i].costFinal + s[i].excess*100000;
				sol->costFinal = s[i].costFinal;
				sol->excess = s[i].excess;
				for(j=0; j<inst->nJobs; j++)
				{
					sol->s[j] = s[i].s[j] ;
				}
				for(j=0; j<inst->mAgents; j++)
				{
					sol->resUsage[j] = s[i].resUsage[j];
				}
			}
			if(s[i].costFinal>c_max){
				c_max = s[i].costFinal;
			}
			//c_media+=s[i].costFinal;
		}
		printf("\n%d ---- ", c_min);
		printf("%d ----", max_ite);
		//c_media=c_media/nThreads;
		printf("%d ---- ", c_max);
		//printf("%d ---- ", c_media);

	}

	free(s[threadIdx.x].s);
	free(s[threadIdx.x].resUsage);

}


Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents)
{
	//printf("Begin createGpuSolution!\n");

	size_t size_solution = sizeof(Solution)
                        				   + sizeof(Ts)*nJobs //vector s
                        				   + sizeof(TresUsage)*mAgents; // vector resUsage
	Solution *d_sol;
	gpuMalloc((void**)&d_sol, size_solution);
	//printf("malloc solution ok!\n");
	//getchar();
	gpuMemset(d_sol,0,size_solution);
	//printf("memset Solution ok!\n");
	//getchar();

	h_solution->s = (Ts*)(d_sol+1);
	h_solution->resUsage = (TresUsage*)(h_solution->s + nJobs);

	//printf("adjusting solution GPU pointers\n");
	//getchar();

	gpuMemcpy(d_sol, h_solution, size_solution, cudaMemcpyHostToDevice);

	//printf("memcpy Solution ok!\n");
	//getchar();

	return d_sol;

}

