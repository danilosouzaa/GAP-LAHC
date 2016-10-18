#include "gSolution.cuh"

const int nThreads = 576;
const int nBlocks = 4;

__global__ void SCHC(Instance *inst, Solution *sol, unsigned int *seed, unsigned int *rank, curandState_t* states, int L_c, int max_ite)
{
		// Parameters of SCHC
		int B_c;
		int N_c;

		// Variation in solution
		int delta;

		// Variable auxiliary
		int aux;

		//Solutions Shared
		__shared__ Solution s[nThreads];
		__shared__ int costFinal[nThreads];

		// Minimal cost
		int c_min;

		// Vector with position for ejection chain
		short int pos[8];

		// Option of neighborhood
		short int op;
		// Size of Ejection Chain
		short int size_chain;

		// iterators and auxiliary
		int i,j,k, ite, flag;

		//Allocation of vetor s and resUsage for thread.
		//s[threadIdx.x].costFinal = (TcostFinal*)malloc(sizeof(TcostFinal)*nThreads);
		s[threadIdx.x].s = (Ts*)malloc(sizeof(Ts)*inst->nJobs);
		s[threadIdx.x].resUsage = (TresUsage*)malloc(sizeof(TresUsage)*inst->mAgents);

		//Initialize curand 
		curand_init(seed[blockIdx.x*nThreads + threadIdx.x],blockIdx.x*nThreads + threadIdx.x,0,&states[blockIdx.x*nThreads + threadIdx.x]);
		
		//Copy solution initial (Solution per block)
		costFinal[threadIdx.x] = sol->costFinal[blockIdx.x];
		for(i=0; i<inst->nJobs; i++)
		{
			s[threadIdx.x].s[i] = sol->s[i + blockIdx.x*inst->nJobs];
		}
		for(i=0; i<inst->mAgents; i++)
		{
			s[threadIdx.x].resUsage[i] = sol->resUsage[i + blockIdx.x*inst->mAgents];
		}
		
		//Define size of L_c for random number between 100 and 150
		L_c = curand(&states[blockIdx.x*nThreads + threadIdx.x])%101 + 50;

		// Initial parametres
		B_c = costFinal[threadIdx.x];
		N_c = 0;
		ite = 0;
		//Loop with conditional number maximal of iteration
		while(ite<=max_ite)
		{
			// Loop for find a solution feasible
			do
			{	
				//op receive what neighborhood (random 0-1)
				op = curand(&states[blockIdx.x*nThreads + threadIdx.x])%2;
						
				aux=0; //value 0 for movement infeasible
				delta = 0; //initial value delta with 0
				if(op == 1) //neighborhood 1 change agent
				{
					pos[0] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->nJobs; //define which job will be modified
					pos[1] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->mAgents; // define new agent for job
					delta = inst->cost[pos[0]*inst->mAgents + pos[1]] - inst->cost[pos[0]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]])]; //Calculate the delta value 
					// Conditional of Capacity and Resource Usage
					if(( s[threadIdx.x].resUsage[pos[1]] + inst->resourcesAgent[pos[0]*inst->mAgents + pos[1]] <= inst->capacity[pos[1]])&&
					(s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[0]])] - inst->resourcesAgent[pos[0]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]])] <= inst->capacity[((int)s[threadIdx.x].s[pos[0]])]))
					{
						aux=1; //value 1 for movement feasible
					}
				}
				else
				{
					aux = 1; //value 1 for movement feasible (assumption)
					size_chain = curand(&states[blockIdx.x*nThreads + threadIdx.x])%6 + 2; //define size_chain 
					pos[0] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->nJobs; //first agent define for ejection chain
					delta -= inst->cost[ pos[0]*inst->mAgents+ ((int)s[threadIdx.x].s[pos[0]])]; //Update delta
					pos[size_chain] = inst->nJobs-1;//initialize last position for comparation
					do{
						pos[size_chain]--;
					}while(((int)s[threadIdx.x].s[pos[0]])== ((int)s[threadIdx.x].s[pos[size_chain]]));//verify if first equal the last
					for(i=1; i<=size_chain; i++) //runs ejection chain
					{	
						pos[i] = curand(&states[blockIdx.x*nThreads + threadIdx.x])%inst->nJobs;//define position i of ejection chain
						k = pos[i]; //k is auxiliary
						//loop for verify feasibly of moviment						
						do{ 
							flag = 0;
							for(j=0; j<i; j++)//verify if the job has already been selected
							{
								if(pos[i]==pos[j])
								{
									flag = 1;  //flag 1 if position has already been selected
									break; //end comparation
								}
							}
							//verify if the position are different, and satisfy the resources and capacity
							if(
								(((int)s[threadIdx.x].s[pos[i]]) != ((int)s[threadIdx.x].s[pos[i-1]]))
								&&(((int)s[threadIdx.x].s[pos[0]]) != ((int)s[threadIdx.x].s[pos[size_chain]])) 
								&&(flag!=1)
								&&(s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[i]])] - inst->resourcesAgent[pos[i]*inst->mAgents + ((int)s[threadIdx.x].s[pos[i]])] + inst->resourcesAgent[pos[i-1]*inst->mAgents + ((int)s[threadIdx.x].s[pos[i]])] <= inst->capacity[((int)s[threadIdx.x].s[pos[i]])])){
								break; //if yes, next position is randomly selected
							}
							pos[i]=(pos[i]+1)%(inst->nJobs);// if no, position is incremment 
						}while(pos[i]!=k);
						if(k==pos[i]){//verify if it was possible get a ejection chain
							aux=0;//if true, no ejection chain was generated
							break;
						}
						delta += inst->cost[pos[i-1]*inst->mAgents+((int)s[threadIdx.x].s[pos[i]])];//update delta 
						delta -= inst->cost[pos[i]*inst->mAgents+((int)s[threadIdx.x].s[pos[i]])];
					}
					delta += inst->cost[pos[size_chain]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]])];//update with last and first position
					if(s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[0]])] - inst->resourcesAgent[pos[0]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]])] + inst->resourcesAgent[pos[size_chain]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]])]>inst->capacity[((int)s[threadIdx.x].s[pos[0]])])
					{
						aux=0;
					}
				}
				
			}
			while(aux==0);
			ite++;
			if ((costFinal[threadIdx.x] + delta < B_c)||(costFinal[threadIdx.x] + delta <= costFinal[threadIdx.x]))
			{
				costFinal[threadIdx.x] += delta;
				if(op==1)
				{
					s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[0]])] -= inst->resourcesAgent[pos[0]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]]) ];
					s[threadIdx.x].resUsage[pos[1]] += inst->resourcesAgent[pos[0]*inst->mAgents + pos[1]];
					s[threadIdx.x].s[pos[0]] = ((char)pos[1]);
				}
				else
				{
					s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[0]])] += inst->resourcesAgent[pos[size_chain]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]])];
					s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[0]])] -= inst->resourcesAgent[pos[0]*inst->mAgents + ((int)s[threadIdx.x].s[pos[0]])];
					aux = ((int)s[threadIdx.x].s[pos[0]]);
					for(i=1; i<=size_chain; i++)
					{
						s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[i]])] += inst->resourcesAgent[pos[i-1]*inst->mAgents + ((int)s[threadIdx.x].s[pos[i]])];
						s[threadIdx.x].resUsage[((int)s[threadIdx.x].s[pos[i]])] -= inst->resourcesAgent[pos[i]*inst->mAgents + ((int)s[threadIdx.x].s[pos[i]])];
						s[threadIdx.x].s[pos[i-1]] = s[threadIdx.x].s[pos[i]];
					}
					s[threadIdx.x].s[pos[size_chain]] = ((char)aux);
				}
			}
			N_c++;
			if(N_c >= L_c)
			{
				B_c = costFinal[threadIdx.x];
				N_c = 0;
			}
			
		}
		
		
		for(j=0;j<inst->nJobs;j++){
			atomicInc(&rank[j * inst->mAgents + ((int)s[threadIdx.x].s[j])],(nThreads*nBlocks)+1);
		}


		if(threadIdx.x < 1)
		{
			c_min = costFinal[threadIdx.x];
			aux = 0;
			for(i=1; i<nThreads; i++)
			{	

				if(costFinal[i]<c_min)
				{	
					c_min = costFinal[i];
					aux = i;
				}
			}
			sol->costFinal[blockIdx.x] = costFinal[aux];
			for(j=0; j<inst->nJobs; j++)
			{	
				sol->s[j + blockIdx.x*inst->nJobs] = s[aux].s[j] ;
			}	
			for(j=0; j<inst->mAgents; j++)
			{
				sol->resUsage[j + blockIdx.x*inst->mAgents] = s[aux].resUsage[j];	
				k = s[aux].resUsage[j];
			}

		}
		__syncthreads();
		//free(s[threadIdx.x].costFinal);
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

