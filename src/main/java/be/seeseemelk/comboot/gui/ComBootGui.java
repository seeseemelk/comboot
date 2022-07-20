package be.seeseemelk.comboot.gui;

import be.seeseemelk.comboot.ComBootServer;
import be.seeseemelk.comboot.Disks;

import javax.swing.*;
import java.awt.*;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.Transferable;
import java.awt.dnd.DnDConstants;
import java.awt.dnd.DropTarget;
import java.awt.dnd.DropTargetDropEvent;
import java.io.File;
import java.io.IOException;
import java.util.List;

public class ComBootGui
{
	private final ComBootServer server;
	private final JFrame frame;
	private final JLabel fileLabel;

	public ComBootGui(ComBootServer server)
	{
		this.server = server;

		frame = new JFrame("ComBoot");
		frame.setMinimumSize(new Dimension(100, 100));
		frame.add(fileLabel = new JLabel("Drag and drop an image file here"));
		fileLabel.setHorizontalAlignment(JLabel.CENTER);
		frame.setDropTarget(new DropTarget()
		{
			@Override
			public synchronized void drop(DropTargetDropEvent event)
			{
				try
				{
					Transferable transferable = event.getTransferable();
					if (!transferable.isDataFlavorSupported(DataFlavor.javaFileListFlavor))
						return;

					event.acceptDrop(DnDConstants.ACTION_COPY);
					List<File> files = (List<File>) transferable.getTransferData(DataFlavor.javaFileListFlavor);
					if (files.isEmpty())
						return;

					File file = files.get(0);
					fileLabel.setText(file.getAbsolutePath().toString());
					server.openFile(Disks.FLOPPY_A, file.toPath());
					server.sendBoot();
				}
				catch (Exception e)
				{
					e.printStackTrace();
				}
			}
		});

		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	}

	public void run() throws IOException
	{
		frame.setVisible(true);
		server.run();
	}

	public void close() throws IOException
	{
		frame.dispose();
	}
}
