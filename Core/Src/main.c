/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2024 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "app_x-cube-ai.h"
#include <math.h> // Per funzioni matematiche come log()


/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#define DATA_SIZE 974 // Dimensione dell'array dei dati
#define UART_TIMEOUT 1000  // Timeout per la trasmissione UART

float mean3[974]={};
float mean5[974]={};
float diff[974]={};
float loggg[974]={};
float mean3_1[974]={};
float mean5_1[974]={};
float diff_1[974]={};
float loggg_1[974]={};
float calculateSkewness(uint16_t data[], int size, float mean, float stddev);
float calculateKurtosis(uint16_t data[], int size, float mean, float stddev);
int v;
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */
// Funzione per calcolare la skewness
float calculateSkewness(uint16_t data[], int size, float mean, float stddev)
{
    float skew = 0.0;
    for (int i = 0; i < size; ++i)
    {
        skew += pow((data[i] - mean) / stddev, 3);
    }
    return skew / size;
}

// Funzione per calcolare la kurtosis
float calculateKurtosis(uint16_t data[], int size, float mean, float stddev)
{
    float kurt = 0.0;
    for (int i = 0; i < size; ++i)
    {
        kurt += pow((data[i] - mean) / stddev, 4);
    }
    return kurt / size;
}
void calculateMovingAverage(uint16_t data[], int size, int window, float result[])
{
    for (int i = 0; i < size; ++i)
    {
        if (i < window - 1)
        {
            result[i] = 0.0;  // Valori iniziali non calcolabili
        }
        else
        {
            float sum = 0.0;
            for (int j = i - window + 1; j <= i; ++j)
            {
                sum += data[j];
            }
            result[i] = sum / window;
        }
    }
}

// Funzione per calcolare le differenze
void calculateDifference(uint16_t data[], int size, float result[])
{
    result[0] = 0.0;  // Prima differenza non calcolabile
    for (int i = 1; i < size; ++i)
    {
        result[i] = data[i] - data[i - 1];
    }
}

// Funzione per calcolare la trasformazione logaritmica
void calculateLogTransformation(uint16_t data[], int size, float result[])
{
    for (int i = 0; i < size; ++i)
    {
        if (data[i] > 0)
        {
            result[i] = log(data[i]);
        }
        else
        {
            result[i] = 0.0;  // Gestione dei valori non positivi
        }
    }
}


/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
ADC_HandleTypeDef hadc1;

TIM_HandleTypeDef htim2;

UART_HandleTypeDef huart2;

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_ADC1_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_TIM2_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

uint8_t buffertx[5];
uint8_t buffertx2[6];
uint8_t buffertx3[4];
//unsigned int uiAnalogData=0;
unsigned int PPG_Value=0;
/*
int cont=0;
int c=0;
int tempo=0;
float tempo1=0;
int BPM=0;
*/
uint16_t uiAnalogData[DATA_SIZE]; // Array per memorizzare i dati
    // Altre variabili necessarie
	float sum, mean, variance, stddev, skewness, kurtosis;
    uint16_t min = UINT16_MAX, max = 0;
    // Array per le nuove feature
        float movingAvg3[DATA_SIZE], movingAvg5[DATA_SIZE];
        float differences[DATA_SIZE], logTransformed[DATA_SIZE];

        int dataCount = 0;  // Contatore per tracciare i dati inseriti



  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_ADC1_Init();
  MX_USART2_UART_Init();
  MX_TIM2_Init();
  MX_X_CUBE_AI_Init();
  /* USER CODE BEGIN 2 */
  HAL_TIM_Base_Start_IT(&htim2);
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {

    /* USER CODE END WHILE */

 // MX_X_CUBE_AI_Process();
    /* USER CODE BEGIN 3 */

	  sum = 0.0;  // Reinizializza la somma
	  variance = 0.0;  // Reinizializza la varianza

	  while (dataCount < DATA_SIZE)
	     {
	  	HAL_ADC_Start(&hadc1);
	  	HAL_ADC_PollForConversion(&hadc1,1000);
	  	HAL_ADC_ConfigChannel(&hadc1, 0);
	  	uiAnalogData[dataCount]=HAL_ADC_GetValue(&hadc1);
	  	HAL_ADC_Stop(&hadc1);
	  	// Aggiornamento minimo e massimo
	  	if (uiAnalogData[dataCount] < min) min = uiAnalogData[dataCount];
	  	if (uiAnalogData[dataCount] > max) max = uiAnalogData[dataCount];
	  	sum += uiAnalogData[dataCount];
	    dataCount++;
	    HAL_Delay(100);
	      }
/*
	  HAL_ADC_Start(&hadc1);
	  HAL_ADC_ConfigChannel(&hadc1, 1);
	  PPG_Value = HAL_ADC_GetValue(&hadc1);
	  HAL_ADC_Stop(&hadc1);
*/


	  // Calcoli solo se l'array è pieno
	      if (dataCount == DATA_SIZE){

	    	  /*
	  // Calcolo della media GSR
	  mean = sum / DATA_SIZE;
	  // Calcolo della varianza  GSR
	  for (int i = 0; i < DATA_SIZE; ++i)
	          {
	          variance += pow(uiAnalogData[i] - mean, 2);
	          }
	          variance /= DATA_SIZE;

	          // Calcolo della deviazione standard GSR
	   stddev = sqrt(variance);

	          // Calcolo skewness e kurtosis GSR
	    skewness = calculateSkewness(uiAnalogData, DATA_SIZE, mean, stddev);
	    kurtosis = calculateKurtosis(uiAnalogData, DATA_SIZE, mean, stddev);
	    */
	    // Calcolo delle nuove feature
	          mean3_1=calculateMovingAverage(uiAnalogData, DATA_SIZE, 3, movingAvg3);
	           mean5_1= calculateMovingAverage(uiAnalogData, DATA_SIZE, 5, movingAvg5);
	            diff_1=calculateDifference(uiAnalogData, DATA_SIZE, differences);
	            loggg_1=calculateLogTransformation(uiAnalogData, DATA_SIZE, logTransformed);
	            /*

	            char buffer[100];  // Buffer per la trasmissione UART
	           	            int len = sprintf(buffer, "Mean: %.2f\r\n", mean);
	           	            HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           	            len = sprintf(buffer, "Standard Deviation: %.2f\r\n", stddev);
	           	            HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           	            len = sprintf(buffer, "Minimum: %u\r\n", min);
	           	            HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           	            len = sprintf(buffer, "Maximum: %u\r\n", max);
	           	            HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           	            len = sprintf(buffer, "Skewness: %.2f\r\n", skewness);
	           	            HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           	            len = sprintf(buffer, "Kurtosis: %.2f\r\n", kurtosis);
	           	            HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           	            len = sprintf(buffer, "Moving Average (3): %.2f\r\n", movingAvg3[DATA_SIZE-1]);
	           				HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           				len = sprintf(buffer, "Moving Average (5): %.2f\r\n", movingAvg5[DATA_SIZE-1]);
	           				HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           				len = sprintf(buffer, "Difference: %.2f\r\n", differences[DATA_SIZE-1]);
	           				HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           				len = sprintf(buffer, "Log Transformed: %.2f\r\n", logTransformed[DATA_SIZE-1]);
	           				HAL_UART_Transmit(&huart2, (uint8_t *)buffer, len, UART_TIMEOUT);
	           				*/
	            for (int i=0; i<974; i++){
	            	mean3[i]=((float)mean3_1[i]);
	            			mean5[i]=((float)mean5_1[i]);
	            			diff[i]=((float)diff_1[i]);
	            			loggg[i]=((float)loggg_1[i]);

	            }


	            HAL_TIM_Base_Stop_IT(&htim2);
	            		sprintf(buffertx, "Acquisizione dati sensori effettuata\n\r");
	            		HAL_UART_Transmit(&huart2, buffertx, strlen(buffertx), 100);


	            		ai_u8 activations[AI_NETWORK_DATA_ACTIVATIONS_SIZE];
	            		ai_u8 in_data[AI_NETWORK_IN_1_SIZE_BYTES];
	            		ai_u8 out_data[AI_NETWORK_OUT_1_SIZE_BYTES];

	            		ai_buffer *ai_input;
	            		ai_buffer *ai_output;

	            		ai_handle network = AI_HANDLE_NULL;
	            		ai_error err;
	            		ai_network_report report;

	            		const ai_handle acts[] = { activations };
	            		err = ai_network_create_and_init(&network, acts, NULL);
	            		if (err.type != AI_ERROR_NONE) {
	            			sprintf(buffertx, "ai init_and_create error\n");
	            			HAL_UART_Transmit(&huart2, buffertx, strlen(buffertx), 100);
	            		}
	            		if (ai_network_get_report(network, &report) != true) {
	            			sprintf(buffertx, "ai get report error\n");
	            			HAL_UART_Transmit(&huart2, buffertx, strlen(buffertx), 100);
	            		}

	            		ai_input = &report.inputs[0];
	            		ai_output = &report.outputs[0];

	            		for (int j = 0; j <974; j++) {

	            			((ai_float *)in_data)[0][j] = mean3[i];
	            			((ai_float *)in_data)[1][j] = mean5[i];
	            			((ai_float *)in_data)[2][j] = diff[i];
	            			((ai_float *)in_data)[3][j] = loggg[i];
	            		}

	            		ai_i32 n_batch;

	            		ai_input = ai_network_inputs_get(network, NULL);
	            		ai_output = ai_network_outputs_get(network, NULL);

	            		ai_input[0].data = AI_HANDLE_PTR(in_data);
	            		ai_output[0].data = AI_HANDLE_PTR(out_data);

	            		n_batch = ai_network_run(network, &ai_input[0], &ai_output[0]);


	            		if (n_batch != 1) {
	            			err = ai_network_get_error(network);
	            			sprintf(buffertx, "ai run error %d, %d\n", err.type, err.code);
	            			HAL_UART_Transmit(&huart2, buffertx, strlen(buffertx), 100);
	            		}
	            		float f[4];

	            				char a[] = { ((char *)out_data)[0], ((char *)out_data)[1], ((char *)out_data)[2], ((char *)out_data)[3] };
	            				char b[] = { ((char *)out_data)[4], ((char *)out_data)[5], ((char *)out_data)[6], ((char *)out_data)[7] };
	            				char c[] = { ((char *)out_data)[8], ((char *)out_data)[9], ((char *)out_data)[10], ((char *)out_data)[11] };

	            				memcpy(&f[0], &a, sizeof(f[0]));
	            				memcpy(&f[1], &b, sizeof(f[1]));
	            				memcpy(&f[2], &c, sizeof(f[2]));


	            				int m=0;
	            				float media=0;
	            				int sum=0;
	            				int cont1 = 0;
	            				v=max(f, sizeof(f));
	            				v=roundf(media);
	            							if(v==0){
	            								sprintf(buffertx, " 0\n\r");
	            							}
	            							if(v==1){
	            								sprintf(buffertx, " 1\n\r");
	            							}
	            							if(v==2){
	            								sprintf(buffertx, " 2\n\r");
	            							}

	            							HAL_UART_Transmit(&huart2, buffertx, strlen(buffertx), 100);

	           				//memset(uiAnalogData, 0, sizeof(uiAnalogData)); //svuota l'array
	           				dataCount=0;//resetta data count
	           				min = UINT16_MAX;
	           				max = 0;

	      }







	    /* Questo nel momento che dobbiamo trasmattere il segnale sulla seriale
		sprintf(buffertx,"%lu\t",uiAnalogData);// prima c'era %Lu
		HAL_UART_Transmit(&huart2,buffertx,sizeof(buffertx), 1000);
		sprintf(buffertx2,"%lu\r\n", 3*PPG_Value);
		HAL_UART_Transmit(&huart2,buffertx2,sizeof(buffertx2), 1000);
		*/


	  	//HAL_Delay(10);
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE2);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 16;
  RCC_OscInitStruct.PLL.PLLN = 336;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
  RCC_OscInitStruct.PLL.PLLQ = 7;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief ADC1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_ADC1_Init(void)
{

  /* USER CODE BEGIN ADC1_Init 0 */

  /* USER CODE END ADC1_Init 0 */

  ADC_ChannelConfTypeDef sConfig = {0};

  /* USER CODE BEGIN ADC1_Init 1 */

  /* USER CODE END ADC1_Init 1 */

  /** Configure the global features of the ADC (Clock, Resolution, Data Alignment and number of conversion)
  */
  hadc1.Instance = ADC1;
  hadc1.Init.ClockPrescaler = ADC_CLOCK_SYNC_PCLK_DIV4;
  hadc1.Init.Resolution = ADC_RESOLUTION_12B;
  hadc1.Init.ScanConvMode = ENABLE;
  hadc1.Init.ContinuousConvMode = DISABLE;
  hadc1.Init.DiscontinuousConvMode = DISABLE;
  hadc1.Init.ExternalTrigConvEdge = ADC_EXTERNALTRIGCONVEDGE_NONE;
  hadc1.Init.ExternalTrigConv = ADC_SOFTWARE_START;
  hadc1.Init.DataAlign = ADC_DATAALIGN_RIGHT;
  hadc1.Init.NbrOfConversion = 2;
  hadc1.Init.DMAContinuousRequests = DISABLE;
  hadc1.Init.EOCSelection = ADC_EOC_SINGLE_CONV;
  if (HAL_ADC_Init(&hadc1) != HAL_OK)
  {
    Error_Handler();
  }

  /** Configure for the selected ADC regular channel its corresponding rank in the sequencer and its sample time.
  */
  sConfig.Channel = ADC_CHANNEL_0;
  sConfig.Rank = 1;
  sConfig.SamplingTime = ADC_SAMPLETIME_3CYCLES;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }

  /** Configure for the selected ADC regular channel its corresponding rank in the sequencer and its sample time.
  */
  sConfig.Channel = ADC_CHANNEL_1;
  sConfig.Rank = 2;
  if (HAL_ADC_ConfigChannel(&hadc1, &sConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN ADC1_Init 2 */

  /* USER CODE END ADC1_Init 2 */

}

/**
  * @brief TIM2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_TIM2_Init(void)
{

  /* USER CODE BEGIN TIM2_Init 0 */

  /* USER CODE END TIM2_Init 0 */

  TIM_ClockConfigTypeDef sClockSourceConfig = {0};
  TIM_MasterConfigTypeDef sMasterConfig = {0};

  /* USER CODE BEGIN TIM2_Init 1 */

  /* USER CODE END TIM2_Init 1 */
  htim2.Instance = TIM2;
  htim2.Init.Prescaler = 999;
  htim2.Init.CounterMode = TIM_COUNTERMODE_UP;
  htim2.Init.Period = 4294967295;
  htim2.Init.ClockDivision = TIM_CLOCKDIVISION_DIV1;
  htim2.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
  if (HAL_TIM_Base_Init(&htim2) != HAL_OK)
  {
    Error_Handler();
  }
  sClockSourceConfig.ClockSource = TIM_CLOCKSOURCE_INTERNAL;
  if (HAL_TIM_ConfigClockSource(&htim2, &sClockSourceConfig) != HAL_OK)
  {
    Error_Handler();
  }
  sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
  sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
  if (HAL_TIMEx_MasterConfigSynchronization(&htim2, &sMasterConfig) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN TIM2_Init 2 */

  /* USER CODE END TIM2_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
/* USER CODE BEGIN MX_GPIO_Init_1 */
/* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOH_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_FALLING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : LD2_Pin */
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);

/* USER CODE BEGIN MX_GPIO_Init_2 */
/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
