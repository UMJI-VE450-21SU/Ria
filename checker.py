if __name__ == '__main__':
  spike_fd = open('spike.out', 'r')
  retire_fd = open('retire.out', 'r')

  spike = spike_fd.readlines()
  retire = retire_fd.readlines()

  for i in range(len(retire)):
    spike_pc = spike[i].strip().split()[2].split('x')[1]
    retire_pc = retire[i].strip().split()[2]
    if spike_pc != retire_pc:
      print(i, spike_pc, retire_pc)
      # break

  spike_fd.close()
  retire_fd.close()
