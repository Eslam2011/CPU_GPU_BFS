#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cuda.h>
#include <device_functions.h>
#include <cuda_runtime_api.h>
#include<time.h>

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <conio.h>
#define NUM_NODES 6
#define num_blks 1
#define half_NUMNODES 4
#define Thread 5
int CPU_NODE = half_NUMNODES;
bool front[NUM_NODES] = { false };
bool visited[NUM_NODES] = { false };


typedef struct
{
	int start;     // Index of first adjacent neigbour node in d_adjLists	
	int length;    // Number of neighbour nodes 
} Node;


__global__ void CUDA_BFS_KERNEL(Node* d_VertixArray, int* d_adjLists, bool* d_front, bool* d_Visited, bool* done, int* d_result)
{
	int id = threadIdx.x + blockIdx.x * blockDim.x;
	if (id > NUM_NODES)
		*done = false;


	if (d_front[id] == true && d_Visited[id] == false)
	{
		printf("%d ", id); //This printf gives the order of vertices in BFS	
		d_front[id] = false;
		d_Visited[id] = true;
		__syncthreads();
		//	int k = 0;
			//int i;
		int start = d_VertixArray[id].start;
		int end = start + d_VertixArray[id].length;
		for (int i = start; i < end; i++)
		{
			int nid = d_adjLists[i];

			if (d_Visited[nid] == false && d_front[nid] == false)
			{
				//printf("%d", nid);
				d_front[nid] = true;

				*done = false;
			}

		}

	}
}


void CPU_BFS(Node* Vertix, int* adjLists, bool* front, bool* Visited, bool done)
{
	done = false;

	for (int i = half_NUMNODES; i < NUM_NODES;i++) {

		if (front[i] == true && Visited[i] == false)
		{

			printf("%d", i);
			front[i] = false;
			Visited[i] = true;


			int start = Vertix[i].start;
			int end = start + Vertix[i].length;
			for (int j = start; j < end; j++)
			{
				int nid = adjLists[j];

				if (Visited[nid] == false && front[nid] == false)
				{
					printf(" %d", nid);
					front[nid] = true;
					done = false;

				}

			}

		}

	}
}


int main()
{
	Node Vertex[NUM_NODES];
	int edges[14];
	int GPU_edges[7];
	int* adjLists = (int*)malloc(sizeof(int*) * 7);
	int* result[half_NUMNODES];
	cudaEvent_t start, stop;
	Node* d_VertexArray;
	int* d_adjLists;
	int* d_result;
	bool done;
	bool* d_done;
	bool* d_front;
	bool* d_Visited;



	Vertex[0].start = 0;
	Vertex[0].length = 2;

	Vertex[1].start = 2;
	Vertex[1].length = 2;

	Vertex[2].start = 4;
	Vertex[2].length = 3;

	Vertex[3].start = 7;
	Vertex[3].length = 3;

	Vertex[4].start = 10;
	Vertex[4].length = 2;

	Vertex[5].start = 12;
	Vertex[5].length = 2;


	GPU_edges[0] = 1;
	GPU_edges[1] = 2;
	GPU_edges[2] = 0;
	GPU_edges[3] = 3;
	GPU_edges[4] = 0;
	GPU_edges[5] = 3;
	GPU_edges[6] = 5;
	edges[7] = 1;
	edges[8] = 2;
	edges[9] = 4;
	edges[10] = 3;
	edges[11] = 5;
	edges[12] = 2;
	edges[13] = 4;




	int source = 0;
	front[source] = true;


	cudaMalloc((void**)&d_VertexArray, sizeof(Node) * half_NUMNODES);
	cudaMemcpy(d_VertexArray, Vertex, sizeof(Node) * half_NUMNODES, cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_adjLists, sizeof(Node) * half_NUMNODES);
	cudaMemcpy(d_adjLists, GPU_edges, sizeof(Node) * half_NUMNODES, cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_front, sizeof(bool) * half_NUMNODES);
	cudaMemcpy(d_front, front, sizeof(bool) * half_NUMNODES, cudaMemcpyHostToDevice);
	cudaMalloc((void**)&d_Visited, sizeof(bool) * half_NUMNODES);
	cudaMemcpy(d_Visited, visited, sizeof(bool) * half_NUMNODES, cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_done, sizeof(bool));
	cudaMalloc((void**)&d_result, sizeof(int*) * NUM_NODES);
	cudaMemcpy(d_result, result, sizeof(int) * half_NUMNODES, cudaMemcpyHostToDevice);
	int count = 0;
	printf("\nBreadth-First Search: ");
	//printf("%d", source);
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	do {
		count++;
		done = true;
		cudaMemcpy(d_done, &done, sizeof(bool), cudaMemcpyHostToDevice);
		CUDA_BFS_KERNEL << <num_blks, Thread >> > (d_VertexArray, d_adjLists, d_front, d_Visited, d_done, d_result);
		cudaMemcpy(&done, d_done, sizeof(bool), cudaMemcpyDeviceToHost);
		cudaMemcpy(&visited, d_Visited, sizeof(bool) * half_NUMNODES, cudaMemcpyDeviceToHost);
		cudaMemcpy(&result, d_result, sizeof(int) * half_NUMNODES, cudaMemcpyDeviceToHost);

	} while (!done);


	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);

	float elapsedTime;
	cudaEventElapsedTime(&elapsedTime, start, stop);

	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	int x = 0;
	for (int i = 0; i < 7; i++) {
		x = GPU_edges[i];
		front[x] = true;
		//printf("\ni =%d , x =%d , visited = %d\n", i, x, visited[x]);
	}


	for (int c = 0; c < NUM_NODES; c++) {
		printf("\ni =%d , d_visited =%d , visited = %d, front =%d, d_front =%d \n  in bfs \n", c, &d_Visited[c], visited[c], front[c], &d_front[c]);
	}





	//int CPU_SourceNode = half_NUMNODES;
	//front[CPU_SourceNode] = true;


	for (int i = 7; i < 14;i++) {
		adjLists[i] = edges[i];

	}


	do {

		done = true;
		CPU_BFS(Vertex, adjLists, front, visited, done);

	} while (!done);

	printf("\nGPU Time: %f s \n", elapsedTime / 1000);
	cudaFree(d_done);
	cudaFree(d_VertexArray);
	cudaFree(d_adjLists);
	cudaFree(d_front);
	cudaFree(d_Visited);
	cudaFree(d_result);

}