#include "gSolution.cuh"

const int nThreads = 576;
const int nBlocks = 4;

__global__ void SCHC(Instance *inst, Solution *sol, unsigned int *seed, unsigned int *rank, curandState_t* states, int L_c)
{
		int B_c;
		int N_c;
		int delta;
		int aux;
		__shared__ Solution s[nThreads];
		int c_min;
		short int aux_p[10];
		short int op;
		short int t;
		int i,j,k, ite, flag;
		
		s[threadIdx.x].costFinal = (TcostFinal*)malloc(sizeof(TcostFinal));
		s[threadIdx.x].s = (Ts*)malloc(sizeof(Ts)*inst->nJobs);
		s[threadIdx.x].resUsage = (TresUsage*)malloc(sizeof(TresUsage)*inst->mAgents);
		curand_init(seed[blockIdx.x*nThreads + threadIdx.x],blockIdx.x*nThreads + threadIdx.x,0,&states[blockIdx.x*nThreads + threadIdx.x]);
		
		s[threadIdx.x].costFinal[0] = sol->costFinal[blockIdx.x];
		
		for(i=0; i<inst->nJobs; i++)
		{
			s[threadIdx.x].s[i] = sol->s[i + blockIdx.x*inst->nJobs];
		}
		
		for(i=0; i<inst->mAgents; i++)
		{
			s[threadIdx.x].resUsage[i] = sol->resUsage[i + blockIdx.x*inst->mAgents];
		}
		
		L_c = curand(&states[blockIdx.x*nThreads + threadIdx.x])%101 + 50;
		B_c = sol->costFinal[blockIdx.x];
		N_c = 0;
		ite = 0;
		
		while(ite<=1000)
		{
			do
			{
				op = curand(&states[blockIdx.x*nThreads + threadIdx.x])%2;
				aux=0;
				
				if(op == 1)
				{
					delta=0;
					aux_p[0] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->nJobs;
					aux_p[1] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->mAgents;
					delta = inst->cost[aux_p[0]*inst->mAgents + aux_p[1]] - inst->cost[aux_p[0]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]])];
					if(( s[threadIdx.x].resUsage[aux_p[1]] + inst->resourcesAgent[aux_p[0]*inst->mAgents + aux_p[1]] <= inst->capacity[aux_p[1]])&&
							(s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[0]])] - inst->resourcesAgent[aux_p[0]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]])] <= inst->capacity[((int)s[threadIdx.x].s[aux_p[0]])]))
					{
						aux=1;
					}
				}
				else
				{
					delta=0;
					aux = 1;
					t = curand(&states[blockIdx.x*nThreads + threadIdx.x])%8 + 2;
					aux_p[0] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->nJobs;
					delta -= inst->cost[ aux_p[0]*inst->mAgents+ ((int)s[threadIdx.x].s[aux_p[0]])];
					for(i=1; i<=t; i++)
					{

						aux_p[i] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->nJobs;
						k = aux_p[i];
						aux_p[t] = inst->nJobs-1;
						do{
							flag = 0;
							for(j=0; j<i; j++)
							{
								if(aux_p[i]==aux_p[j])
								{
									flag = 1;
								}
							}
							if((((int)s[threadIdx.x].s[aux_p[i]]) != ((int)s[threadIdx.x].s[aux_p[i-1]]))&&( ((int)s[threadIdx.x].s[aux_p[0]]) != ((int)s[threadIdx.x].s[aux_p[t]]) ) &&(flag!=1)&&(s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[i]])] - inst->resourcesAgent[aux_p[i]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[i]])] + inst->resourcesAgent[aux_p[i-1]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[i]])] <= inst->capacity[((int)s[threadIdx.x].s[aux_p[i]])])){
								break;
							}
							aux_p[i]=(aux_p[i]+1)%(inst->nJobs);
						}while(aux_p[i]!=k);
						if(k==aux_p[i]){
							aux=0;
						}
						delta += inst->cost[aux_p[i-1]*inst->mAgents+((int)s[threadIdx.x].s[aux_p[i]])];
						delta -= inst->cost[aux_p[i]*inst->mAgents+((int)s[threadIdx.x].s[aux_p[i]])];
					}
					delta += inst->cost[aux_p[t]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]])];
					if(s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[0]])] - inst->resourcesAgent[aux_p[0]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]])] + inst->resourcesAgent[aux_p[t]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]])]>inst->capacity[((int)s[threadIdx.x].s[aux_p[0]])])
					{
						aux=0;
					}
				}
			}
			while(aux==0);

			if ((s[threadIdx.x].costFinal[0] + delta < B_c)||(s[threadIdx.x].costFinal[0] + delta <= s[threadIdx.x].costFinal[0]))
			{
				s[threadIdx.x].costFinal[0] += delta;
				if(op==1)
				{
					s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[0]])] -= inst->resourcesAgent[aux_p[0]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]]) ];
					s[threadIdx.x].resUsage[aux_p[1]] += inst->resourcesAgent[aux_p[0]*inst->mAgents + aux_p[1]];
					s[threadIdx.x].s[aux_p[0]] = ((char)aux_p[1]);
				}
				else
				{
					s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[0]])] += inst->resourcesAgent[aux_p[t]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]])];
					s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[0]])] -= inst->resourcesAgent[aux_p[0]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[0]])];
					aux = ((int)s[threadIdx.x].s[aux_p[0]]);
					for(i=1; i<=t; i++)
					{
						s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[i]])] += inst->resourcesAgent[aux_p[i-1]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[i]])];
						s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[aux_p[i]])] -= inst->resourcesAgent[aux_p[i]*inst->mAgents + ((int)s[threadIdx.x].s[aux_p[i]])];
						s[threadIdx.x].s[aux_p[i-1]] = s[threadIdx.x].s[aux_p[i]];
					}
					s[threadIdx.x].s[aux_p[t]] = ((char)aux);
				}
			}
			N_c++;
			if(N_c >= L_c)
			{
				B_c = s[threadIdx.x].costFinal[0];
				N_c = 0;
			}
			ite++;
		}
		
		__syncthreads();
		for(j=0;j<inst->nJobs;j++){
			atomicInc(&rank[j * inst->mAgents + ((int)s[threadIdx.x].s[j])],(nThreads*nBlocks)+1);
		}
		__syncthreads();

		if(threadIdx.x < 1)
		{
			c_min = s[threadIdx.x].costFinal[0];
			aux = threadIdx.x;
			for(i=0; i<nThreads; i++)
			{	
				
				if(s[i].costFinal[0]<c_min)
				{
					c_min = s[i].costFinal[0];
					aux = i;
				}
			}
			
			sol->costFinal[blockIdx.x] = s[aux].costFinal[0];
			for(j=0; j<inst->nJobs; j++)
			{
				sol->s[j + blockIdx.x*inst->nJobs] = s[aux].s[j] ;
			}
			for(j=0; j<inst->mAgents; j++)
			{
				sol->resUsage[j + blockIdx.x*inst->mAgents] = s[aux].resUsage[j];	
			}
		}	
		free(s[threadIdx.x].costFinal);
		free(s[threadIdx.x].s);
		free(s[threadIdx.x].resUsage);
}


Solution* createGPUsolution(Solution* h_solution,TnJobs nJobs, TmAgents mAgents)
{
	//printf("Begin createGpuSolution!\n");

	size_t size_solution = sizeof(Solution)
												   + sizeof(TcostFinal)*nBlocks
												   + sizeof(Ts)*(nJobs*nBlocks) //vector s
												   + sizeof(TresUsage)*(mAgents*nBlocks); // vector resUsage

	Solution *d_sol;
	gpuMalloc((void**)&d_sol, size_solution);
	//printf("malloc solution ok!\n");
	//getchar();
	gpuMemset(d_sol,0,size_solution);
	//printf("memset Solution ok!\n");
	//getchar();
	h_solution->costFinal = (TcostFinal*)(d_sol+1);
	h_solution->s = (Ts*)(h_solution->costFinal + nBlocks);
	h_solution->resUsage = (TresUsage*)(h_solution->s + (nJobs*nBlocks));

	//printf("adjusting solution GPU pointers\n");
	//getchar();

	gpuMemcpy(d_sol, h_solution, size_solution, cudaMemcpyHostToDevice);

	//printf("memcpy Solution ok!\n");
	//getchar();

	return d_sol;

}

