#include  "guloso.h"

 

const int nBlock = 28;
const int nThread = 576;

//Create vector with priority of allocation jobs in Agents 
int* inicializeVector(Instance *inst, int p1, int p2)
{
    int *vOrdem;
    int *vParametro;
    int i, j;
    int aux1,aux2,iAux1,iAux2;
    vOrdem = (int*)malloc(sizeof(int)*(inst->nJobs *inst->mAgents));
    vParametro = (int*)malloc(sizeof(int)*(inst->nJobs *inst->mAgents));
    for(i=0; i<inst->nJobs ; i++)
    {
        for(j=0; j<inst->mAgents; j++)
        {
            vParametro[iReturn(i,j,inst->nJobs ,inst->mAgents)] = p1*inst->cost[iReturn(i,j,inst->nJobs ,inst->mAgents)] + p2*inst->resourcesAgent[iReturn(i,j,inst->nJobs ,inst->mAgents)];
            vOrdem[iReturn(i,j,inst->nJobs ,inst->mAgents)]=j;
        }
    }
    for(i=0; i<inst->nJobs ; i++)
    {
        for(j= inst->mAgents-1; j>=0; j--)
        {
            for(aux1= j-1; aux1>=0; aux1--)
            {
                if(vParametro[iReturn(i,j,inst->nJobs ,inst->mAgents)]<vParametro[iReturn(i,aux1,inst->nJobs ,inst->mAgents)])
                {
                    aux2 = vParametro[iReturn(i,j,inst->nJobs ,inst->mAgents)];
                    iAux2 = vOrdem[iReturn(i,j,inst->nJobs ,inst->mAgents)];
                    vParametro[iReturn(i,j,inst->nJobs ,inst->mAgents)]= vParametro[iReturn(i,aux1,inst->nJobs ,inst->mAgents)];
                    vOrdem[iReturn(i,j,inst->nJobs ,inst->mAgents)]=vOrdem[iReturn(i,aux1,inst->nJobs ,inst->mAgents)];;
                    vParametro[iReturn(i,aux1,inst->nJobs ,inst->mAgents)]=aux2;
                    vOrdem[iReturn(i,aux1,inst->nJobs ,inst->mAgents)]=iAux2;
                }
            }
        }
    }
    free(vParametro);
    return vOrdem;


}





Solution* guloso(Instance *inst, int p1, int p2)
{
    int *vOrdem;
    int *allocated=(int*)malloc(sizeof(int)*inst->nJobs );
    int i,j,agent;
    int cont=0;
    memset(allocated,0,sizeof(int)*inst->nJobs );
    
    Solution *sol = allocationPointersSolution(inst);
    
    sol->costFinal[0]=0;
    vOrdem=inicializeVector(inst,p1,p2);
    for(i=0; i<inst->nJobs ; i++)
    {
        for(j=0; j<inst->mAgents; j++)
        {
            agent=vOrdem[iReturn(i,j,inst->nJobs ,inst->mAgents)];
            /*printf("n: %d \n",iReturn(i,j,inst->nJobs ,inst->mAgents));*/
            if((allocated[i]==0)&&(inst->resourcesAgent[iReturn(i,agent,inst->nJobs ,inst->mAgents)]+sol->resUsage[agent]<=inst->capacity[agent]))
            {
                allocated[i]=1;
                sol->s[i] = ((char)agent);
                sol->costFinal[0]+=inst->cost[iReturn(i,agent,inst->nJobs ,inst->mAgents)];
                sol->resUsage[agent]+=inst->resourcesAgent[iReturn(i,agent,inst->nJobs ,inst->mAgents)];
                cont++;
            }
        }
    }
    for(i=1;i<nBlock;i++){
    	for(j=0;j<inst->nJobs;j++){
    		sol->s[i*inst->nJobs + j] = sol->s[j];
    	}
    	for(j=0;j<inst->mAgents;j++){
    		sol->resUsage[i*inst->mAgents + j] = sol->resUsage[j];
    	}
    	sol->costFinal[i] = sol->costFinal[0];
    }
    	
    if(cont!=inst->nJobs ){
        sol->costFinal[0]=0;
    }
    free(allocated);
    free(vOrdem);
    return sol;
}

