#region usings
using System;
using System.ComponentModel.Composition;

using VVVV.PluginInterfaces.V1;
using VVVV.PluginInterfaces.V2;
using VVVV.Utils.VColor;
using VVVV.Utils.VMath;

using VVVV.Core.Logging;
#endregion usings

namespace VVVV.Nodes
{
	#region PluginInfo
	[PluginInfo(Name = "Spiral", Category = "Spread", Help = "Basic template with one value in/out", Tags = "")]
	#endregion PluginInfo
	public class SpreadSpiralNode : IPluginEvaluate
	{
		#region fields & pins
		[Input("Debug", IsSingle=true, IsBang=true)]
		public ISpread<bool> FDebug;
		
		[Input("Size", IsSingle=true, DefaultValue = 6)]
		public IDiffSpread<int> FSize;
		
		[Output("Output")]
		public ISpread<int> FOutput;
		
		[Import()]
		public ILogger FLogger;
		#endregion fields & pins
		
		
		int[,] matrix;
		int m_size;
		int currentCount;
		
		//called when data for any output pin is requested
		public void Evaluate(int SpreadMax)
		{
			m_size = FSize[0];
			matrix = new int[m_size, m_size];
			currentCount = 1;
			
			if (FSize.IsChanged)
			{
				DrawSpiral();
			}
			//FLogger.Log(LogType.Debug, "hi tty!");
		}
		
		
		public void DrawSpiral()
		{
			//x,y   x, y+size-1
			//x+1, y+size-1     x+size-1, y+size-1
			//x+size-1, y+size-2    x+size-1, y
			//x+size-2, y   x+1, y
			int x = 0, y = 0, size = m_size;
			
			while (size > 0)
			{
				for (int i = y; i <= y + size - 1; i++)
				{
					matrix[x, i] = currentCount++;
				}
				
				for (int j = x + 1; j <= x + size - 1; j++)
				{
					matrix[j, y + size - 1] = currentCount++;
				}
				
				for (int i = y + size - 2; i >= y; i--)
				{
					matrix[x + size - 1, i] = currentCount++;
				}
				
				for (int i = x + size - 2; i >= x + 1; i--)
				{
					matrix[i, y] = currentCount++;
				}
				
				x = x + 1;
				y = y + 1;
				size = size - 2;
			}
			PrintMatrix();
		}
		
		private void PrintMatrix()
		{
			for (int i = 0; i < m_size; i++)
			{
				FOutput.SliceCount = m_size * m_size;
				for (int j = 0; j < m_size; j++)
				{
					if (FDebug[0]) FLogger.Log(LogType.Debug, "i: " +i + ", j: " + j +" value: " + matrix[i, j].ToString());
					//					Console.Write(matrix[i, j]);
					//					Console.Write("   ");
					
					int curr = i * m_size + j;
					
					FOutput[curr] = matrix[i,j];
				}
				//				Console.WriteLine();
			}
		}
		
	}
	
	
	
	
}
