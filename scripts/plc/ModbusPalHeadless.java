/* Minimal headless wrapper for the official ModbusPal 1.6b JAR.
 * API verified with javap against the downloaded binary (not assumed from master).
 * Compile: javac --release 8 -cp ModbusPal.jar ModbusPalHeadless.java
 */
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Collections;
import modbuspal.main.ModbusPalProject;
import modbuspal.slave.ModbusSlave;
import modbuspal.slave.ModbusRegisters;
import modbuspal.link.ModbusTcpIpLink;
import modbuspal.link.ModbusLinkListener;

public final class ModbusPalHeadless {
    public static void main(String[] args) throws Exception {
        System.setProperty("java.awt.headless", "true");
        ModbusPalProject project = new ModbusPalProject();
        ModbusSlave slave = new ModbusSlave(1);
        slave.setName("PLC industrial simulado - laboratorio");
        slave.setEnabled(true);
        ModbusRegisters registers = slave.getHoldingRegisters();
        registers.create(0, 4);
        int[] values = {250, 1000, 1, 750};
        for (int i = 0; i < values.length; i++) {
            registers.setValue(i, values[i]);
        }
        project.addModbusSlave(slave);
        project.setSlaveEnabled(1, true);
        if (args.length == 1 && "--self-test".equals(args[0])) {
            for (int i = 0; i < values.length; i++) {
                if (registers.getValue(i) != values[i]) throw new IllegalStateException("Register mismatch");
            }
            System.out.println("SELF-TEST OK: ModbusPal unit=1, addresses=0..3, values=250,1000,1,750; no socket opened");
            return;
        }
        if (args.length != 0) throw new IllegalArgumentException("No arguments, or --self-test");
        boolean labAddress = false;
        for (NetworkInterface network : Collections.list(NetworkInterface.getNetworkInterfaces())) {
            if (!network.isUp() || network.isLoopback()) continue;
            for (InetAddress address : Collections.list(network.getInetAddresses())) {
                if ("192.168.212.30".equals(address.getHostAddress())) labAddress = true;
                else if (!address.isLinkLocalAddress()) {
                    throw new IllegalStateException("Non-lab address detected: " + address.getHostAddress());
                }
            }
        }
        if (!labAddress) throw new IllegalStateException("Expected isolated PLC address 192.168.212.30");
        final ModbusTcpIpLink link = new ModbusTcpIpLink(project, 502);
        Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
            public void run() { link.stop(); }
        }));
        link.start(new ModbusLinkListener() {
            public void linkBroken() {
                System.err.println("Modbus link stopped");
            }
        });
        System.out.println("ModbusPal starting: TCP 502, unit=1, addresses=0..3. Verify listener with ss and a client.");
    }
}
