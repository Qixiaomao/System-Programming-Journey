#include <stdio.h>
#include <stdlib.h>

// define our handcart (tile size), it is usually 16x16
#define TILE_WIDTH 16

// Matrix Multiplication Evolution
/*ver1.0 不加Shared memory, 让工友直接去Global memory里去读*/


// ==========================================
// 核心 Kernel: Version 1.0 (Naive Matmul)
// 纯 Global Memory 交互，没有任何 Shared Memory
// ==========================================
__global__ void naiveMatMul(float *A, float *B, float *C, int width) {
    // 1. 确认工友的“绝对物理坐标”（他在整个 1024x1024 大矩阵里的位置）
    // blockIdx.y * blockDim.y 跳过前面的大区块，threadIdx.y 是区块内的局部行号
    int Row = blockIdx.y * blockDim.y + threadIdx.y; 
    int Col = blockIdx.x * blockDim.x + threadIdx.x; 

    // 2. 安全检查：防止越界（虽然 1024 能被 16 整除，但这是架构师的好习惯）
    if (Row < width && Col < width) {
        float Cvalue = 0.0f; // 每个工友自己手里的暂存器（存在极速的物理寄存器里）

        // 3. 极其惨烈的循环：直接去 Global Memory 拿数据
        for (int k = 0; k < width; ++k) {
            // A 矩阵：Row 固定，k 在变。这是同行读取，触发【合并访存】！(好)
            float a_element = A[Row * width + k]; 
            
            // B 矩阵：k 在变，Col 固定。这是跨行（按列）读取！
            // 灾难发生：极度严重的【非合并访存】(Uncoalesced Access)！(极差)
            float b_element = B[k * width + Col]; 

            Cvalue += a_element * b_element;
        }

        // 4. 算完之后，把结果写回到 C 矩阵的绝对物理坐标里
        C[Row * width + Col] = Cvalue;
    }
}


int main(){
    int width = 1024;
    size_t size = width * width * sizeof(float);
    printf("开始初始化 1024x1024的矩阵...\n");

    // 在Host上分配内存并放入测试数据
    float *h_A = (float*)malloc(size);
    float *h_B = (float*)malloc(size);
    float *h_C = (float*)malloc(size);

    // 方便验证结果 A=1.0, B=2.0
    for(int i = 0; i < width*width; i++){
        h_A[i] = 1.0f;
        h_B[i] = 2.0f;
    }

    // 在GPU显存上挖坑
    float *d_A, *d_B, *d_C;
    cudaMalloc((void **)&d_A, size);
    cudaMalloc((void **)&d_B, size);
    cudaMalloc((void **)&d_C, size);
   
    // 把CPU数据装车 ，搬运到GPU显存
    printf("数据正从 CPU 搬运到 GPU (Global Memory)...\n");
    cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
    cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);

    // ==========================================
    // 步骤 4：配置 GPU 兵力，并发起冲锋！(启动 Kernel)
    // ==========================================
    // 1个 Block = 16 x 16 = 256 个线程 (工友)
    dim3 dimBlock(TILE_WIDTH, TILE_WIDTH); 
    
    // Grid 决定了要派多少个 Block (工友大队) 过去
    // 宽度 1024 / 16 = 64。所以我们需要 64 x 64 = 4096 个 Block！
    dim3 dimGrid(width / TILE_WIDTH, width / TILE_WIDTH); 

    printf("召唤 GPU 大军：启动 %d 个 Block，每个 Block %d 个 Thread...\n", 
           (width/TILE_WIDTH)*(width/TILE_WIDTH), TILE_WIDTH*TILE_WIDTH);

    // ==========================================
    // 发起冲锋！调用 Kernel 函数
    // <<<Grid维度, Block维度>>> 告诉 GPU 怎么分配兵力
    // (d_A, d_B, d_C, width) 是传给工友的参数
    // ==========================================
    naiveMatMul<<<dimGrid, dimBlock>>>(d_A, d_B, d_C, width);


     // 确保 GPU 全部算完 (同步)
    cudaDeviceSynchronize(); 


    // ==========================================
    // 步骤 5：把结果从 GPU 搬回 CPU，并验证
    // ==========================================
    cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);

    // 验证逻辑：A全是1，B全是2。根据矩阵乘法规则，C 的每个元素应该是 1*2 * 1024 = 2048
    bool success = true;
    for (int i = 0; i < width * width; i++) {
        if (h_C[i] != 2048.0f) {
            success = false;
            printf("翻车了！在索引 %d 处，期望值 2048.0，实际值 %f\n", i, h_C[i]);
            break;
        }
    }

    if (success) {
        printf(" Success! GPU 完美算出了 1024x1024 的 Tiled GEMM！\n");
        printf(" 抽查结果: C[0] = %f\n", h_C[0]);
    }
    
    // ==========================================
    // 打扫战场：释放所有的 CPU 内存和 GPU 显存
    // ==========================================
    cudaFree(d_A); cudaFree(d_B); cudaFree(d_C);
    free(h_A); free(h_B); free(h_C);

    return 0;
}