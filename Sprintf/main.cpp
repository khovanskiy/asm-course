extern "C" int __cdecl print(char*, const char*, const char*);
#include "stdio.h"
#include "conio.h"
#include "string.h"

int letterToInt(char c)
{
	if (c >= 'a' && c <= 'f') return c - 'a' + 10;
	else if (c >= 'A' && c <= 'F') return c - 'A' + 10;
	else return c - '0';
}

char intToLetter(long long c)
{
	if (c < 10) return (char)('0' + c);
	else return (char)('A' + c - 10);
}

int max(int a, int b)
{
	if (a > b) return a;
	else return b;
}

void print2(char *out_buf, const char *format, const char *hex_number) 
{
	int i = 0;
	bool sign = false, left = false, space = false, zero = false, negation = false;
	int width = 0;
	while (format[i] != 0) 
	{
		if (format[i] >= '0' && format[i] <= '9') width = width * 10 + format[i] - '0';
		if ((format[i] == '0') && (width == 0)) zero = true;
		if (format[i] == ' ') space = true;
		if (format[i] == '+') sign = true;
		if (format[i] == '-') left = true;
		i++;
	}
	char* ans_buffer = new char[max(width, 40)];
	int out_buf_length = 0;
	while (out_buf[out_buf_length] != 0) out_buf_length++;
	int start = 0;
	if (hex_number[0] == '-') 
	{
		negation = true;
		start = 1;
	}
	i = start;
	int length = 0;
	while (hex_number[i] != 0) 
	{
		i++;
		length++;
	}
	unsigned int b0 = 0, b1 = 0, b2 = 0, b3 = 0;
	for (i = max(start, start + length - 8); i < start + length; i++)
	{
		b3 = (b3 << 4) + letterToInt(hex_number[i]);
	}
	for (i = max(start, start + length - 16); i < start + length - 8; i++)
	{
		b2 = (b2 << 4) + letterToInt(hex_number[i]);
	}
	for (i = max(start, start + length - 24); i < start + length - 16; i++)
	{
		b1 = (b1 << 4) + letterToInt(hex_number[i]);
	}
	for (i = max(start, start + length - 32); i < start + length - 24; i++)
	{
		b0 = (b0 << 4) + letterToInt(hex_number[i]);
	}
	if (b0 == 0 && b1 == 0 && b2 == 0 && b3 == 0)
	{
		negation = false;
	}
	if (length == 32 && hex_number[start] > '7') 
	{
		negation = !negation;
		b0 = ~b0;
		b1 = ~b1;
		b2 = ~b2;
		b3 = ~b3;
		if (b3 + 1 == 0)
		{
			if (b2 + 1 == 0) 
			{
				if (b1 + 1 == 0)
				{
					b0++;
				}
				b1++;
			}
			b2++;
		}
		b3++;
	}
	int cur_pos = 0;
	long long carry = 0;
	while (b0 > 0 || b1 > 0 || b2 > 0 || b3 > 0)
	{
		carry = b0;
		b0 = carry / 10;
		carry = ((carry % 10) << 32) + b1;
		b1 = carry / 10;
		carry = ((carry % 10) << 32) + b2;
		b2 = carry / 10; 
		carry = ((carry % 10) << 32) + b3;
		b3 = carry / 10;
		ans_buffer[cur_pos++] = intToLetter(carry % 10);
	}
	if (cur_pos == 0) ans_buffer[cur_pos++] = '0';
	if (negation || sign) 
	{
		if (negation) ans_buffer[cur_pos++] = '-';
		else ans_buffer[cur_pos++] = '+';
	} 
	else if (space)
	{
		ans_buffer[cur_pos++] = ' ';
	}
	if (!left)
	{
		while (cur_pos < width)
		{
			if (zero) 
			{
				ans_buffer[cur_pos++] = '0';
				if (ans_buffer[cur_pos - 2] > '9' || ans_buffer[cur_pos - 2] < '0')
				{
					char tmp = ans_buffer[cur_pos - 2];
					ans_buffer[cur_pos - 2] = ans_buffer[cur_pos - 1];
					ans_buffer[cur_pos - 1] = tmp;
				}
			}
			else
			{
				ans_buffer[cur_pos++] = ' ';
			}			
		}
	}
	int pos = 0;
	while (cur_pos > 0)
	{
		out_buf[pos++] = ans_buffer[--cur_pos];
	}
	while (pos < width)
	{
		out_buf[pos++] = ' ';
	}
	out_buf[pos++] = 0;
	delete ans_buffer;
}/**/

int main()
{
	char buffer[2048], buffer2[2048];
	//const char* hex_number = "-f";
	const char* hex_number[] = {"-80000000000000000000000000000000"};//, "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", "-ffffffffffffffffffffffffffffffff", "8fffffffffffffffffffffffffffffff", "7fffffffffffffffffffffffffffffff", "-8fffffffffffffffffffffffffffffff", "-7fffffffffffffffffffffffffffffff", "-f", "abcd", "123", "0", "-0","-1", "fffffabcdf", "-fffffabcdf","ffffffffffffffffff","0123456789abcdef"};
	const char* formats[] = { "-"};//, "+", " ", "0", "", "-+", "- ", "+ ", "+0", "-0"," 0", "0+10","-15", " 10"," + - 5", "0 + 50", "0-0"};
	
	int count = sizeof(hex_number) / sizeof(char*);
	int formats_count = sizeof(formats) / sizeof(char*);

	int errors_count = 0;
	for (int j = 0; j < formats_count; ++j)
	{
		printf("===FORMAT===:%s\n",formats[j]);
		for (int i = 0; i < count; ++i)
		{
		
				printf("HEX NUMBER = %s\n", hex_number[i]);
				print(buffer, formats[j], hex_number[i]);
				printf("RESULT ASM= %s:[%i]\n", buffer, strlen(buffer));
		
				print2(buffer2, formats[j], hex_number[i]);
				printf("RESULT C  = %s:[%i]\n", buffer2, strlen(buffer2));

				int diff = strcmp(buffer, buffer2) != 0 ? 1 : 0;
				printf("EQUALS = %i\n", strcmp(buffer, buffer2));

				errors_count+=diff;
		
				
			/*int x;
			sscanf_s(hex_number, "%x", &x);
			printf("%0+10i\n", x);*/
		}
	}
	
	printf("\nTOTAL ERRORS: %i\n", errors_count);
	_getch();
	return 0;
}