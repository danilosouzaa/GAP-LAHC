#include <stdio.h>
#include <stdlib.h>
#include <curand.h>
#include <curand_kernel.h>
#include <sys/time.h>


#include "gpulib/types.h"
#include "gpulib/gpu.cuh"

#include "Instance.h"
#include "Solution.h"
#include "gSolution.cuh"
#include "guloso.h"

const int nThreads = 576;
const int nBlocks = 4;
int main(int argc, char *argv[]){
	//counter
	int i,j;
	
	
	//Position and Best Solution
	int pos_best;
	int cost_best;
	
	//Parameters of heuristic SCHC
	int l_c=0;
	
	//Variable with size of struct solution
	size_t size_solution;
	
	//File name of instance GAP
	const char *fileName = argv[1];
	
	//Variable with numbers of GPU's
	int deviceCount = 0;
	
	//Commands for verify use correct of GPU
	cudaError_t error_id = cudaGetDeviceCount(&deviceCount);
	if (error_id != cudaSuccess)
	{
		printf("cudaGetDeviceCount returned %d\n-> %s\n", (int)error_id, cudaGetErrorString(error_id));
		printf("Result = FAIL\n");
		exit(1);
	}
	if(deviceCount == 0)
	{
		printf("No GPU found :(");
		exit(1);
	}
	else
	{
		printf("Found %d GPUs!\n", deviceCount);
		gpuSetDevice(0);
		printf("GPU 0 initialized!\n");
	}
	
	//Pointer of instance and solution for use in GPU (device)
	Instance *d_instance;
	Solution *d_solution;
	
	//Pointer of states for use with curand
	curandState_t* states;
	cudaMalloc((void**) &states, (nThreads*nBlocks) * sizeof(curandState_t));
	
	//Pointer of seed for use with curand (host)
	unsigned int *h_seed = (unsigned int*)malloc(sizeof(unsigned int)*(nThreads*nBlocks));
	srand(time(NULL));
	for(i=0;i<(nThreads*nBlocks);i++){
		h_seed[i] = rand()%100000;
	}
	
	//Pointer of instance and solution for use in GPU (device)
	Instance *inst = loadInstance(fileName); // Load the Instance 
	Solution *sol;

	
	//Generate of solution initial with greedy heuristic
	if(fileName[0]=='e'){
		sol = guloso(inst,1,20);
	}else{
		sol = guloso(inst,1,2);
	}
	
	//Definy of Solution size
	size_solution = sizeof(Solution)
							+ sizeof(TcostFinal)*nBlocks
							+ sizeof(Ts)*(inst->nJobs*nBlocks) //vector s
							+ sizeof(TresUsage)*(inst->mAgents*nBlocks); //vector resUsage
	
	//Reallocation of pointers Instance and Solution for GPU (device)
	d_instance = createGPUInstance(inst, inst->nJobs, inst->mAgents);
	d_solution = createGPUsolution(sol,inst->nJobs, inst->mAgents);
	
	//Pointer of rank in host, use for compute frequency of solution
	unsigned int *h_rank = (unsigned int*)malloc(sizeof(unsigned int)*inst->nJobs*inst->mAgents);
	memset(h_rank,0,sizeof(unsigned int)*inst->nJobs*inst->mAgents);
	
	//Pointers seed and rank in device (GPU)
	unsigned int *d_rank;
	unsigned int *d_seed;
	
	//Event and gpu for contability time 
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	
	// Allocation of pointer and copy value in d_seed (Device)
	gpuMalloc((void*)&d_seed, sizeof(unsigned int)*(nThreads*nBlocks));
	gpuMemcpy(d_seed, h_seed, sizeof(unsigned int)*(nThreads*nBlocks), cudaMemcpyHostToDevice);

	// Allocation of pointer and copy value in d_rank (Device)
	gpuMalloc((void* ) &d_rank, sizeof(unsigned int)*inst->nJobs*inst->mAgents);
	gpuMemcpy(d_rank, h_rank,sizeof(unsigned int)*inst->nJobs*inst->mAgents , cudaMemcpyHostToDevice);
	
	
	//int blockSize;      // The launch configurator returned block size 
	//int minGridSize;    // The minimum grid size needed to achieve the maximum occupancy for a full device launch 
	//int gridSize;
	//int N = 1000000;
	
	//cudaOccupancyMaxPotentialBlockSize(&minGridSize, &blockSize, SCHC, 0, N);
	
	//printf("block size %d\n",blockSize);
	//printf("Min Grid %d\n",minGridSize);
	
	//Initial count time
	cudaEventRecord(start);
	
	//Execute kernell of SCHC
	printf("TESTE\n");
	SCHC<<<nBlocks,nThreads>>>(d_instance,d_solution, d_seed ,d_rank, states, l_c);

	//Final count time
	cudaEventRecord(stop);

	
	//copy solution of device to host
	gpuMemcpy(sol, d_solution, size_solution, cudaMemcpyDeviceToHost);
	
	//copy rank (frequency) of device to host
	gpuMemcpy(h_rank, d_rank,sizeof(unsigned int)*inst->nJobs*inst->mAgents , cudaMemcpyDeviceToHost);
	
	//syncronize of output GPU
	cudaEventSynchronize(stop);
	
	//Compute time of execution in kernel GPU
	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	printf("%.4fms\n", milliseconds);

	
	
	//reallocation pointers of Instance
	inst->cost = (Tcost*)(inst+1);
	inst->resourcesAgent =(TresourcesAgent*) (inst->cost +(inst->nJobs*inst->mAgents));
	inst->capacity =(Tcapacity*) (inst->resourcesAgent + (inst->nJobs*inst->mAgents));

	//reallocation pointers of Solution
	sol->costFinal = (TcostFinal*)(sol+1);
	sol->s = (Ts*)(sol->costFinal + nBlocks);
	sol->resUsage = (TresUsage*)(sol->s + (inst->nJobs*nBlocks));
	pos_best=0;
	cost_best  = sol->costFinal[0];
	printf("cost final: %d\n",sol->costFinal[0]);
	for(i=1;i<nBlocks;i++){
		printf("cost final: %d\n",sol->costFinal[i]);
		if(sol->costFinal[i]<cost_best){
			pos_best = i;
			cost_best = sol->costFinal[i]; 
		}
	}
	
	printf("Cost best solution: %d\n",cost_best);
	for(i=0;i<inst->nJobs;i++){
		printf("%d ", sol->s[i+inst->nJobs*pos_best]+1);
		
	}
	printf("\n");
	
	//Create file .dat for use in LP
	createDat(inst, h_rank, fileName);
	create_solution(sol,inst,pos_best,fileName);
	create_frequency(inst, h_rank, fileName);
	//Free memory allocated
	gpuFree(d_instance);
	gpuFree(d_solution);
	gpuFree(d_rank);
	gpuFree(d_seed);
	gpuFree(states);
	free(inst);
	free(sol);

	
	return 0;
}
