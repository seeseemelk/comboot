package be.seeseemelk.comboot.gui;

import be.seeseemelk.comboot.ComBootServer;

import javax.swing.*;
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
					server.openFile(file.toPath());
					server.sendBoot();
				}
				catch (Exception e)
				{
					e.printStackTrace();
				}
			}
		});
	}

	public void run() throws IOException
	{
		frame.setVisible(true);
		server.run();
	}
}
