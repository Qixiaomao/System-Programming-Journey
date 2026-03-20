#include <stdio.h>
#include <stdlib.h>

#define TILE_WIDTH 16

// Matrix Multiplication Evolution
// ver2.0 



__global__ void tiledMatMul(float *A, float *B, float *C, int width){
    // 1. 确定工友的全局坐标 (Row, col) 和 局部坐标 (tx, ty)
    int tx = threadIdx.x;
    int ty = threadIdx.y;
    int Row = blockIdx.y * TILE_WIDTH + ty;
    int Col = blockIdx.x * TILE_WIDTH + tx;


    // 2. 开辟气海 ： 声明 16x16的Shared_memory
    __shared__ float ds_A[TILE_WIDTH][TILE_WIDTH];
    __shared__ float ds_B[TILE_WIDTH][TILE_WIDTH];



    // 3.周天搬运 滑动窗口与合并访存
    // for 循环，让256个工友在一个Block 在A行 和 B的列一块的滑动
    // 每个工友拿着暂存器
   float Cvalue = 0.0f;
   for(int p  = 0; p < width/TILE_WIDTH; ++p){
        /*
        剑招核心：256个人同时伸手，去Global Memory 拿数据！
        C=AxB:到ds_A拿A数据, ds_B拿B数据
        */
       ds_A[ty][tx] = A[Row * width + (p * TILE_WIDTH + tx)];
       //ds_B[ty][tx] = B[col + (p * TILE_WIDTH + ty) * width];
       ds_B[ty][tx] = B[(p*TILE_WIDTH+ty)*width + Col];
       // 关门
       __syncthreads();


  // 4. 内景杀伐 Shared_Memory 极速计算 , 气海里算16次乘加
   for(int k = 0; k < TILE_WIDTH; ++k){
    Cvalue += ds_A[ty][k] * ds_B[k][tx];
   }
   // 等所有人算完，再进入下一个Phase覆盖气海的数据 
   __syncthreads();

   
}
     // 5. 收剑入鞘 写回结果
    if(Row < width && Col < width){
        C[Row*width+Col] = Cvalue;
    }

  

}


int main(){
    int width = 1024;
    size_t size = width * width * sizeof(float);
    printf("开始初始化 1024x1024的矩阵...\n");

    // Host 分配内存并放入测试数据
    float *h_A = (float*)malloc(size);
    float *h_B = (float*)malloc(size);
    float *h_C = (float*)malloc(size);

    // 方便验证结果A=1.0， B=2.0
    for(int i = 0; i < width*width; i++){
        h_A[i] = 1.0f;
        h_B[i] = 2.0f;
    }

    // GPU上“挖坑”
    float *d_A, *d_B, *d_C;
    cudaMalloc((void**)&d_A, size);
    cudaMalloc((void**)&d_B, size);
    cudaMalloc((void**)&d_C, size);

    // 把CPU数据装车，搬运到GPU显存
    printf("数据正从CPU搬运到GPU(Global Memory)...\n");
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    // 第四步，配置GPU兵力，发起冲锋！启动Kernel
    // 1 个Block = 16 x 16 = 256 线程（工友

    // Grid 决定了派多少个Block 工友大队过去
    dim3 dimGrid(width/TILE_WIDTH, width/TILE_WIDTH);
    dim3 dimBlock(TILE_WIDTH, TILE_WIDTH);

    printf("召唤GPU大军：启动%d 个 Block, 每个Block %d 个Thread...\n",(width/TILE_WIDTH)*(width/TILE_WIDTH),TILE_WIDTH*TILE_WIDTH);
    

    // 告诉GPU怎么分配兵力 (d_A, d_B, d_C, width) 传给工友的参数
    tiledMatMul<<<dimGrid,dimBlock>>>(d_A, d_B, d_C, width);

    // GPU 同步,将结果从GPU 搬回到CPU，并验证
    cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);

    // 验证逻辑：A全是1，B全是2。根据矩阵乘法规则，C的每个元素应该是1*2*1024 = 2048
    bool success = true;
    for(int i = 0; i < width * width;i++){
        if(h_C[i] != 2048.0f){
            success = false;
            printf("翻车了！在索引 %d 处，期望值 2048.0,实际值 %f\n",i,h_C[i]);
            break;
        }
    }

    if(success){
        printf("Success!GPU 完美算出了 1024x1024 的 Tiled GEMM!\n");
        printf("抽查结果: C[0] = %f\n",h_C[0]);
    }

    return 0;
}