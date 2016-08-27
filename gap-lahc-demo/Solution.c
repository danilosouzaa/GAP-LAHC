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
		printf("Job %d allocated in Agent %d.\n",i+1, sol->s[i]+1);
	}
	for(i=0;i<inst->mAgents;i++){
		printf("Resources Usage in Agent %d: %d.\n",i+1,sol->resUsage[i]);
	}
}

void schc_cpu(Solution *sol, Instance *inst, int L_c){

	int B_c;
	int N_c=0;
	int delta;
	int j;
	Solution *s = allocationPointersSolution(inst);
	short int aux1;
	short int aux2;
	short int op;
	int i;
	s->costFinal = sol->costFinal;
	for (i=0;i<inst->nJobs;i++){
		s->s[i]=sol->s[i];
	}
	for(j=0;j<inst->mAgents;j++){
		s->resUsage[j]=sol->resUsage[j];
	}
	i=0;
	B_c = s->costFinal;
	while(i<600000){
		op=rand()%2;
		if(op==1){
			do{
				aux1=rand()%inst->nJobs;
				aux2=rand()%inst->mAgents;
				delta =  inst->cost[aux1*inst->mAgents+aux2] - inst->cost[aux1*inst->mAgents+s->s[aux1]];

			}while(s->resUsage[aux2] + inst->resourcesAgent[aux1*inst->mAgents + aux2] > inst->capacity[aux2]);
		}else{
			do{
				aux1=rand()%inst->nJobs;
				do{
					aux2=rand()%inst->nJobs;
				}while(aux1==aux2);
				delta = inst->cost[aux1*inst->mAgents + s->s[aux2]] + inst->cost[aux2*inst->mAgents+s->s[aux1]] - inst->cost[aux1*inst->mAgents+s->s[aux1]] - inst->cost[aux2*inst->mAgents+s->s[aux2]];
			}while((s->resUsage[s->s[aux1]] - inst->resourcesAgent[aux1*inst->mAgents+s->s[aux1]] + inst->resourcesAgent[aux2*inst->mAgents+s->s[aux1]] > inst->capacity[s->s[aux1]])
				||(s->resUsage[s->s[aux2]] - inst->resourcesAgent[aux2*inst->mAgents+s->s[aux2]] + inst->resourcesAgent[aux1*inst->mAgents + s->s[aux2]]> inst->capacity[s->s[aux2]]));
		}
		if((s->costFinal + delta < B_c)||(s->costFinal + delta <= s->costFinal)){
			s->costFinal = s->costFinal + delta;
			if(op==1){
				s->resUsage[s->s[aux1]]-= inst->resourcesAgent[aux1*inst->mAgents+s->s[aux1]];
				s->resUsage[s->s[aux1]]+= inst->resourcesAgent[aux1*inst->mAgents+aux2];
				s->s[aux1]=aux2;
			}else{
				s->resUsage[s->s[aux1]]-= inst->resourcesAgent[aux1*inst->mAgents+s->s[aux1]];
				s->resUsage[s->s[aux1]]+= inst->resourcesAgent[aux2*inst->mAgents+s->s[aux1]];
				s->resUsage[s->s[aux2]]-= inst->resourcesAgent[aux2*inst->mAgents+s->s[aux2]];
				s->resUsage[s->s[aux2]]+= inst->resourcesAgent[aux1*inst->mAgents+s->s[aux2]];
				delta=s->s[aux1];
				s->s[aux1]=s->s[aux2];
				s->s[aux2]=s->s[aux1];
			}
		}
		N_c++;
		if(N_c>=L_c){
			B_c = s->costFinal;
			N_c = 0;
		}
		i++;
		printf("%d\n",i);

	}
	printf("custo final: %d\n",s->costFinal);


}


void createDat(Instance *inst, unsigned int *rank,const char *fileName){
	FILE *f;
	char nf[20];
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
		for(i=1;i<=inst->nJobs;i++){
			fprintf(f,"%d ",i);
		}
		fprintf(f,":=\n");
		for(j=1;j<=inst->mAgents;j++){
			fprintf(f,"%d \t", j);
			for(i=1;i<=inst->nJobs;i++){
				fprintf(f,"%d ",inst->cost[(i-1)*inst->mAgents + (j-1)]);
			}
			if(j==inst->mAgents){
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
		for(i=1;i<=inst->nJobs;i++){
			fprintf(f,"%d ",i);
		}
		fprintf(f,":=\n");
		for(j=1;j<=inst->mAgents;j++){
			fprintf(f,"%d \t", j);
			for(i=1;i<=inst->nJobs;i++){
				fprintf(f,"%d ",rank[(i-1)*inst->mAgents + (j-1)]);
			}
			if(j==inst->mAgents){
				fprintf(f,";");
			}
			fprintf(f,"\n");
		}
		fprintf(f,"\n");

		fprintf(f,"end;");
	}
	fclose(f);


}
