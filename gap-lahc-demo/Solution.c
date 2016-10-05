#include "Solution.h"

const int nThreads = 576;
const int nBlocks = 28;

Solution* allocationPointersSolution(Instance *inst){
	size_t size_solution = sizeof(Solution)
									+ sizeof(TcostFinal)*nBlocks
									+ sizeof(Ts)*(inst->nJobs*nBlocks) //vector s
									+ sizeof(TresUsage)*(inst->mAgents*nBlocks); //vector resUsage
	Solution* sol;
	sol = (Solution*)malloc(size_solution);
	assert(sol!=NULL);
	memset(sol,0,size_solution);
	sol->costFinal = (TcostFinal*)(sol+1);
	sol->s = (Ts*)(sol->costFinal + nBlocks);
	sol->resUsage = (TresUsage*)(sol->s + (inst->nJobs*nBlocks));
	return sol;
}

void showSolution(Solution *sol, Instance *inst){
/*	int i;
	printf("Data of Solution:\n");
	printf("Cost of Solution: %d\n", sol->costFinal);
	printf("Excess of capacity in Solution: %d\n", sol->excess);
	for(i=0;i<inst->nJobs;i++){
		printf("Job %d allocated in Agent %d.\n",i+1, sol->s[i]+1);
	}
	for(i=0;i<inst->mAgents;i++){
		printf("Resources Usage in Agent %d: %d.\n",i+1,sol->resUsage[i]);
	}*/
}

void schc_cpu(Solution *sol, Instance *inst, int L_c){

}
void create_solution(Solution *sol, Instance *inst,int pos_best, const char *fileName){
		FILE *f;
		char nf[30]="";
		strcat(nf,"MIP_");
		strcat(nf,fileName);
		strcat(nf,".txt");
		int i;
		f = fopen (nf,"w");
		if(f==NULL){
			printf("erro \n ");
		}else{
			for(i=0;i<inst->nJobs;i++){
				fprintf(f,"x(%d,%d)\n",i+1,sol->s[i + inst->nJobs*pos_best]+1);
			}
		}
		fclose(f);
}
void create_frequency(Instance *inst, unsigned int *rank, const char *fileName){
			FILE *f;
			char nf[30]="";
			strcat(nf,"Freq_");
			strcat(nf,fileName);
			strcat(nf,".txt");
			int i,j;
			f = fopen (nf,"w");
			if(f==NULL){
				printf("erro \n ");
			}else{
				for(i=0;i<inst->nJobs;i++){
					for(j=0;j<inst->mAgents; j++){
						if(rank[j*inst->mAgents + i]>0){
							fprintf(f,"x(%d,%d) = %d \n",i+1, j+1 , rank[i*inst->mAgents + j] );
						}
					}
				}
			}
			fclose(f);
			printf("Create frenquecy ok!\n");
}

void createDat(Instance *inst, unsigned int *rank,const char *fileName){
	FILE *f;
	char nf[20]="";
	strcat(nf,fileName);
	strcat(nf,".dat");
	int i,j;
	f = fopen (nf,"w");
	if(f==NULL){
		printf("erro \n ");
	}else{
		fprintf(f,"data;\n\n");
		fprintf(f,"param n:= %d;\n\n", inst->nJobs);
		fprintf(f,"param m:= %d;\n\n", inst->mAgents);

		fprintf(f,"param cost: ");
		for(i=1;i<=inst->mAgents;i++){
			fprintf(f,"%d ",i);
		}
		fprintf(f,":=\n");
		for(j=1;j<=inst->nJobs;j++){
			fprintf(f,"%d \t", j);
			for(i=1;i<=inst->mAgents;i++){
				fprintf(f,"%d ",inst->cost[(j-1)*inst->mAgents + (i-1)]);
			}
			if(j==inst->nJobs){
				fprintf(f,";");
			}
			fprintf(f,"\n");
		}
		fprintf(f,"\n");

		fprintf(f,"param resources: ");
		for(i=1;i<=inst->mAgents;i++){
			fprintf(f,"%d ",i);
		}
		fprintf(f,":=\n");
		for(j=1;j<=inst->nJobs;j++){
			fprintf(f,"%d \t", j);
			for(i=1;i<=inst->mAgents;i++){
				fprintf(f,"%d ",inst->resourcesAgent[(j-1)*inst->mAgents + (i-1)]);
			}
			if(j==inst->nJobs){
				fprintf(f,";");
			}
			fprintf(f,"\n");
		}
		fprintf(f,"\n");

		fprintf(f,"param capacity:= ");
		for(j=1;j<=inst->mAgents;j++){
			fprintf(f,"%d \t %d", j , inst->capacity[j-1]);

			if(j==inst->mAgents){
				fprintf(f,";");
			}
			fprintf(f,"\n");
		}
		fprintf(f,"\n");

		fprintf(f,"param freq: ");
		for(i=1;i<=inst->mAgents;i++){
			fprintf(f,"%d ",i);
		}
		fprintf(f,":=\n");
		for(j=1;j<=inst->nJobs;j++){
			fprintf(f,"%d \t", j);
			for(i=1;i<=inst->mAgents;i++){
				fprintf(f,"%d ",rank[(j-1)*inst->mAgents + (i-1)]);
			}
			if(j==inst->nJobs){
				fprintf(f,";");
			}
			fprintf(f,"\n");
		}
		fprintf(f,"\n");
	}

	fprintf(f,"end;");
	fclose(f);

}
