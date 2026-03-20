#include <stdio.h>
#include <stdlib.h>

// define our handcart (tile size), it is usually 16x16 or 32x32
#define TILE_WIDTH 16

// running GPU kernel function
// GPU 四步走：1.协同搬砖 Load, 2.拉警戒线 syncthreads 3.疯狂点乘计算 4.拉警戒线
__global__ void MatrixMulTiled(float *d_A, float *d_B, float *d_C, int width){
    // 步骤 0 ：向SM 申请两辆小推车 (shared memory), 用来装A和B得分块
    // __shared__ 关键字及其重要，它告诉编译器：把这块内存放在极速得芯片内部
    __shared__ float ds_A[TILE_WIDTH][TILE_WIDTH];
    __shared__ float ds_B[TILE_WIDTH][TILE_WIDTH];

    // 获取当前Thread 的相对工位 （在Block内的二维坐标）
    int tx = threadIdx.x;
    int ty = threadIdx.y;

    // 获取当前 Thread 负责计算得最终结果矩阵C 得全局绝对坐标
    int row = blockIdx.y * TILE_WIDTH + threadIdx.y;
    int col = blockIdx.x * TILE_WIDTH + threadIdx.x;

    float pValue = 0.0f; // 存在寄存器里，用来累加这一步计算得结果

    // 接下来写一个for 循环，一车一车地拉砖（遍历所有地tile) , 总共需要拉 width / TILE_WIDTH 趟次
    // 循环的次数：总宽度除以小推车的宽度， m 代表当前的批次 phase
    for (int m = 0; m < width /TILE_WIDTH;++m){
        // 第一步：搬砖 load to shared memory
        // 每个人 (tx,ty) 负责从A和B的Global Memory 里各拿一个块砖，放进推车
        // 这里的索引计算及其烧脑，我们在下面单独解释
        ds_A[ty][tx] = d_A[row * width + (m*TILE_WIDTH + tx)];
        // 正常编写的代码 ds_B[ty][tx] = d_B[(m * TILE_WIDTH + ty) * width + col];
        // 破坏性的代码编写版本
        ds_B[ty][tx] = d_B[col * width + (m*TILE_WIDTH + ty)];

        // 第二步：拉起警戒线 （Sync) ; 必须等BLock 里的256个人 (16x16) 全部把手里的砖放进推车里，才能往下走
        __syncthreads();


        // 第三步：疯狂输出 (compute)
        // 在推车里装满了一小块 A 与 B，然后放在shared memory 完成这个16个元素的点乘累加
        for(int k=0; k < TILE_WIDTH; ++k){
            pValue += ds_A[ty][k] * ds_B[k][tx];
        }

        // 第四步：再次拉起警戒线（Sync)
        __syncthreads();
    }


    // 最后把结果写回Global Memory
    d_C[row * width + col] = pValue;
}

// CPU 部分，遵循五步走：
// 1.CPU准备数据 malloc (分配系统内存) 2.GPU挖坑(cudaMalloc 分配显存) 3.数据发往GPU(cudaMemcpy 从Host->Device) 4.召唤GPU大军(<<Grid, Block>>) 5.结果运回CPU （cudaMemcpy）

int main() {
    // 这里未来会写 cudaMalloc, cudaMemcpy 等 CPU 端的调度代码
    // 设定矩阵大小：1024x1024
    int width = 1024;
    size_t size = width * width * sizeof(float);
    printf("开始初始化 1024x1024 的矩阵...\n");

    // ==========================================
    // 步骤 1：在 CPU (Host) 上分配内存并放入测试数据
    // ==========================================
    float *h_A = (float*)malloc(size);
    float *h_B = (float*)malloc(size);
    float *h_C = (float*)malloc(size);

    // 为了方便验证结果，给A填1.0，B填2.0
    for(int i = 0; i < width * width;i++){
        h_A[i] = 1.0f;
        h_B[i] = 2.0f;
    }

    // ==========================================
    // 步骤 2：在 GPU (Device) 显存上“挖坑”
    // ==========================================
    float *d_A, *d_B, *d_C;
    cudaMalloc((void **)&d_A, size);
    cudaMalloc((void **)&d_B, size);
    cudaMalloc((void **)&d_C, size);

    // ==========================================
    // 步骤 3：把 CPU 的数据装车，搬运到 GPU 显存
    // ==========================================
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


    // 真正的计算发生在这里！瞬间完成！
    MatrixMulTiled<<<dimGrid, dimBlock>>>(d_A, d_B, d_C, width);

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